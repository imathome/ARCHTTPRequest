//
//  HTTPRequest.m
//  appcore
//
//  Created by Samuel Colak on 12/14/11.
//  Copyright (c) 2011 Im-At-Home BV. All rights reserved.
//

#import "HTTPRequest.h"

@interface HTTPRequest () {
		
@private
    
	NSURLConnection *_connection;
	NSMutableURLRequest *_request;
    NSString *_saveToStream;
    kHTTPCode _responseCode;
    NSMutableData *_responseData;
    BOOL _inProgress;
    int64_t _fileSize;
    int64_t _received;
    
    NSFileHandle *_handle;
    
}

@end

@implementation HTTPRequest

	@synthesize delegate;
	
    @synthesize headers=_headers;
    @synthesize contentType=_contentType;

    @synthesize password=_password;
    @synthesize username=_username;
    @synthesize bodyContent=_bodyContent;
    @synthesize saveToStream=_saveToStream;

    #pragma mark - Instantiation

    + (HTTPRequest *) requestWithURL:(NSURL *)url
    {		
        return [[HTTPRequest alloc] initWithURL:url timeout:10.0 method:@"PUT"];
    }

	+ (HTTPRequest *) requestWithURL:(NSURL *)url method:(NSString *)method
	{		
		return [[HTTPRequest alloc] initWithURL:url timeout:10.0 method:method];
	}

    - (id) initWithURL:(NSURL *)url 
    {
        return [self initWithURL:url timeout:10.0 method:@"PUT"];
    }

    - (id) initWithURL:(NSURL *)url timeout:(float)timeout method:(NSString *)method
	{        
		self = [super init];
		if (self) {
			_URL = url;		
            _saveToStream = nil;
            _responseCode = kHTTPCodeUndefined;
            _responseData = nil;
            _inProgress = NO;
            _contentType = @"text/plain; charset=utf-8";
            _headers = [[NSMutableDictionary alloc] init];
            _request = [NSMutableURLRequest requestWithURL:_URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeout]; //NSURLRequestUseProtocolCachePolicy
            [_request setHTTPMethod:method];
		}
        
		return self;
	}

    #pragma mark - Properties and getters

	- (NSURL *) getURL
	{
		return _URL;
	}

	- (NSMutableURLRequest *) getRequest
	{
		return _request;
	}
	
    - (BOOL) getInProgress
    {
        return _inProgress;
    }

	- (NSData *) getResponseData
	{
		return _responseData;
	}
    
    - (int64_t) getResponseSize
    {
        return _fileSize;
    }

	- (kHTTPCode) getResponseStatusCode
	{
		return _responseCode;
	}

    - (void) setSaveToStream:(NSString *)saveToStream
    {
        _saveToStream = saveToStream;
                
        if ([[NSFileManager defaultManager] fileExistsAtPath:_saveToStream]) {
            [[NSFileManager defaultManager] removeItemAtPath:_saveToStream error:nil];
        }        

    }

    #pragma mark - Functions

	- (void) addRequestHeader:(NSString *)key value:(NSString *)data
	{
        [_headers setValue:data forKey:key];
	}

	- (void) start
	{
        
        if (_inProgress) return;
        _inProgress = YES;
        
        _responseCode = kHTTPCodeUndefined;
        _received = 0;
        
        if (_saveToStream) {
            
        } else {
            _responseData = [[NSMutableData alloc] init];        
        }

        [_request addValue:_contentType forHTTPHeaderField:@"Content-Type"];

        if (_headers.count > 0) {
            for (NSString *key in _headers.allKeys) {
                [_request addValue:[_headers valueForKey:key] forHTTPHeaderField:key];
            }
        }
                                
        if (_bodyContent) {
            [_request addValue:[NSString stringWithFormat:@"%d", _bodyContent.length] forHTTPHeaderField:@"Content-Length"];
            [_request setHTTPBody: _bodyContent];        
        }
        
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        
        [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_connection start];
                
		if (_connection) {
            if (delegate && [delegate respondsToSelector:@selector(request:initialized:)]) {
                [delegate request:self initialized:_URL];
            }			
		} else {
			// connection failed ...
            _responseCode = kHTTPCodeServerServiceUnavailable;            
            if (delegate && [delegate respondsToSelector:@selector(request:failed:)]) {
                [delegate request:self failed:nil];
            }
            _inProgress = NO;
		}
				
	}

    #pragma mark - Delegate related functions

    - (BOOL) connection:(NSURLConnection *) connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
    {
        return YES; //[protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate];
    }

    - (void) connection:(NSURLConnection *) connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
    {
        // NSLog(@"challenge received");
        // if you want to execute your own challenge functionality here....        
        if (delegate && [delegate respondsToSelector:@selector(request:receivedChallenge:)]) {
            [delegate request:self receivedChallenge:challenge];
        } else {
            // automate the response using the username / password information..
            if ([challenge previousFailureCount] == 0 && ![challenge proposedCredential]) {
                NSURLCredential *_credentials = [NSURLCredential credentialWithUser:_username password:_password persistence:NSURLCredentialPersistenceNone];
                [[challenge sender] useCredential:_credentials forAuthenticationChallenge:challenge];                
            } else {
                if (delegate && [delegate respondsToSelector:@selector(request:authenticationFailed:)]) {
                    [delegate request:self authenticationFailed:challenge];
                } else {
                    [[challenge sender] cancelAuthenticationChallenge:challenge];
                }
            }
        }
    }

	- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
	{
#if DEBUG        
		NSLog(@"Function = %@ / Bytes sent = %d of %d", self.URL, totalBytesWritten, totalBytesExpectedToWrite);
#endif        
        
        if (delegate && [delegate respondsToSelector:@selector(request:sent:total:)]) {
            [delegate request:self sent:totalBytesWritten total:totalBytesExpectedToWrite];
        }

	}

    - (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
    {
        // did receive data        
        
        if (_saveToStream && _handle) {            
            [_handle writeData:data];
        } else {
            [_responseData appendData:data];
        }

#if DEBUG        
		NSLog(@"Function = %@ / Bytes received = %lld of %lld", _URL, _received, _fileSize);
#endif        

        _received += data.length;
        
        if (delegate && [delegate respondsToSelector:@selector(request:received:total:)]) {
            [delegate request:self received:_received total:_fileSize];
        }
        
    } 

    - (void) connectionDidFinishLoading:(NSURLConnection *)connection
    {
        if (_saveToStream && _handle) {
            
            [_handle closeFile];
            
            if ((_received == _fileSize) || (_fileSize == -1)) {
            
                if (delegate && [delegate respondsToSelector:@selector(request:fileDownloaded:)]) {
                    [delegate request:self fileDownloaded:_saveToStream];
                }
                
            } else {
                
                // delete the errored file !!

                if ([[NSFileManager defaultManager] fileExistsAtPath:_saveToStream]) {
                    [[NSFileManager defaultManager] removeItemAtPath:_saveToStream error:nil];
                }        

                if (delegate && [delegate respondsToSelector:@selector(request:failed:)]) {
                    [delegate request:self failed:nil];
                }
                
            }
            
        } else {
            
            if (delegate && [delegate respondsToSelector:@selector(request:receivedData:)]) {
                [delegate request:self receivedData:_responseData];
            }            
            
        }
        _responseData = nil; // dealloc memory for responsedata..
    }

	- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
	{           
        
        NSHTTPURLResponse *_httpResponse = (NSHTTPURLResponse *)response;
        
        _responseCode = (kHTTPCode)_httpResponse.statusCode;
        _fileSize = response.expectedContentLength;
        
        if (_saveToStream) {     
            
            // we need to create the file at this point...

            [[NSFileManager defaultManager] createFileAtPath:_saveToStream contents:nil attributes:nil];
            _handle = [NSFileHandle fileHandleForWritingAtPath:_saveToStream];

            if (_handle == nil) {
                // failed...        
                NSLog(@"Error creating file @ %@", _saveToStream);
            }
            
        }        
        
        if (delegate && [delegate respondsToSelector:@selector(request:connected:)]) {
            [delegate request:self connected:response];
        }        
        
        _httpResponse = nil;
        _inProgress = NO;
        
	}

    - (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
    {
        
        _responseCode = kHTTPCodeServerInternalServer;
        
        if (_handle) {
            [_handle closeFile];
        }
        
        if (delegate && [delegate respondsToSelector:@selector(request:failed:)]) {
            [delegate request:self failed:error];
        }
        
        _inProgress = NO;
        
    }

    - (void) dealloc
    {
        _request = nil;
        _responseData = nil;
        _headers = nil;
        delegate = nil;
    }
 

@end
