//
//  HTTPRequest.h
//  appcore
//
//  Created by Samuel Colak on 12/14/11.
//  Copyright (c) 2011 Im-At-Home BV. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kHTTPCodeUndefined = 0,
    kHTTPCodeContinue = 100,
    kHTTPCodeSwitchingProtocol = 101,
    kHTTPCodeOK = 200,
    kHTTPCodeCreated = 201,
    kHTTPCodeAccepted = 202,
    kHTTPCodeNonAuthoritiveAnswer = 203,
    kHTTPCodeNoAnswer = 204,
    kHTTPCodeResetContent = 205,
    kHTTPCodePartialContent = 206,
    kHTTPCodeRedirectMultipleChoices = 300,
    kHTTPCodeRedirectMovedPermanently = 301,
    kHTTPCodeRedirectFound = 302,
    kHTTPCodeRedirectSeeOther = 303,
    kHTTPCodeRedirectNotModified = 304,
    kHTTPCodeRedirectUseProxy = 305,
    kHTTPCodeRedirectTemporaryRedirect = 306,
    kHTTPCodeClientBadRequest = 400,
    kHTTPCodeClientUnauthorized = 401,
    kHTTPCodeClientPaymentRequired = 402,
    kHTTPCodeClientForbidden = 403,
    kHTTPCodeClientNotFound = 404,
    kHTTPCodeClientMethodNotAllowed = 405,
    kHTTPCodeClientNotAcceptable = 406,
    kHTTPCodeClientProxyAuthenticationRequired = 407,
    kHTTPCodeClientRequestTimeout = 408,
    kHTTPCodeClientConflict = 409,
    kHTTPCodeClientGone = 410,
    kHTTPCodeClientLengthRequired = 411,
    kHTTPCodeClientPreconditionFailed = 412,
    kHTTPCodeClientRequestEntityTooLarge = 413,
    kHTTPCodeClientRequestURITooLong = 414,
    kHTTPCodeClientUnsupportedMediaType = 415,
    kHTTPCodeClientRequestedRangeNotSatisfiable = 416,
    kHTTPCodeClientExpectationFailed = 417,
    kHTTPCodeServerInternalServer = 500,
    kHTTPCodeServerNotImplemented = 501,
    kHTTPCodeServerBadGateway = 502,
    kHTTPCodeServerServiceUnavailable = 503,
    kHTTPCodeServerGatewayTimeout = 504,
    kHTTPCodeServerHTTPVersionNotSupported = 505
} kHTTPCode;

@class HTTPRequest;

@protocol HTTPRequestDelegate <NSObject>

@required

@optional

    - (void) request:(HTTPRequest *)request initialized:(NSURL *) url;
    - (void) request:(HTTPRequest *)request connected:(NSURLResponse *)response;
    - (void) request:(HTTPRequest *)request failed:(NSError *) error;
    - (void) request:(HTTPRequest *)request receivedData:(NSData *)data;

    - (void) request:(HTTPRequest *)request fileDownloaded:(NSString *)filename;

    - (void) request:(HTTPRequest *)request receivedChallenge:(NSURLAuthenticationChallenge *)challenge;
    - (void) request:(HTTPRequest *)request authenticationFailed:(NSURLAuthenticationChallenge *)challenge;
    - (void) request:(HTTPRequest *)request received:(NSInteger)bytes total:(int64_t)total;
    - (void) request:(HTTPRequest *)request sent:(NSInteger)bytes total:(int64_t)total;

@end

@interface HTTPRequest : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
	
	NSURL *_URL;
    NSMutableDictionary *_headers;
	
}

	@property (nonatomic, assign) id<HTTPRequestDelegate> delegate;

    @property (atomic, retain) NSMutableDictionary *headers;
    @property (nonatomic, retain) NSString *contentType;
    @property (nonatomic, retain) NSString *username;
    @property (nonatomic, retain) NSString *password;
    @property (nonatomic, retain) NSData *bodyContent;

	@property (nonatomic, readonly, getter = getURL) NSURL *URL;
	@property (nonatomic, readonly, getter = getRequest) NSMutableURLRequest *request;
	
	@property (nonatomic, readonly, getter = getResponseData) NSData *responseData;
	@property (nonatomic, readonly, getter = getResponseStatusCode) kHTTPCode responseStatusCode;
    @property (nonatomic, readonly, getter = getInProgress) BOOL inProgress;
    @property (nonatomic, readonly, getter = getResponseSize) int64_t responseSize;

    @property (nonatomic, retain, setter = setSaveToStream:) NSString *saveToStream;

    + (HTTPRequest *) requestWithURL:(NSURL *)url;
	+ (HTTPRequest *) requestWithURL:(NSURL *)url method:(NSString *)method;

	- (id) initWithURL:(NSURL *)url;
    - (id) initWithURL:(NSURL *)url timeout:(float)timeout method:(NSString *)method;

	- (void) addRequestHeader:(NSString *)key value:(NSString *)data;
	- (void) start;

@end
