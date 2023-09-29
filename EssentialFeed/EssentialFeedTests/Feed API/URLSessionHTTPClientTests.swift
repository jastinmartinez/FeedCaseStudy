//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 27/9/23.
//

import Foundation
import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    
    func test_getFromURL_PerformGetRequestURL() {
        
        let exp = expectation(description: "wait for completion")
        let url = anyURL()
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _  in }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequest() {
        
        let error = NSError(domain: "a given error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "wait for completion")
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case .success:
                XCTFail("Expect failure but instead got \(result)")
            case .failure(let capturedError as NSError):
                XCTAssertEqual(error.localizedDescription, capturedError.localizedDescription   )
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_FailsOnRequestError() {
        let requestError = NSError(domain: "a given erro", code: 1)
        let receivedError = resultOnError(data: nil, response: nil, error: requestError)
        XCTAssertEqual(requestError.localizedDescription, receivedError?.localizedDescription)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultOnError(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultOnError(data: nil, response: anyURLResponse(), error: nil))
        XCTAssertNotNil(resultOnError(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultOnError(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultOnError(data: nil, response: anyURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultOnError(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultOnError(data: anyData(), response: anyURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultOnError(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultOnError(data: anyData(), response: anyURLResponse(), error: nil))
    }
    
    func test_getFromURL_succedsOnHTTPUrlResponseWithData() {
        let anyResponse = anyHTTPURLResponse()
        let anyData = anyData()
        
        let capturedValue = resultValuesFor(data: anyData, response: anyResponse, error: nil)
        
        XCTAssertEqual(capturedValue?.data, anyData)
        XCTAssertEqual(capturedValue?.httpResponse.url, anyResponse.url)
        XCTAssertEqual(capturedValue?.httpResponse.statusCode, anyResponse.statusCode)
    }
    
    func test_getFromURL_succedsWithEmptyDataOnHTTPUrlResponseWithData() {
        let anyResponse = anyHTTPURLResponse()
        
        let capturedValue = resultValuesFor(data: nil, response: anyResponse, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(capturedValue?.data, emptyData)
        XCTAssertEqual(capturedValue?.httpResponse.url, anyResponse.url)
        XCTAssertEqual(capturedValue?.httpResponse.statusCode, anyResponse.statusCode)
    }
    
    //    MARK: Helpers
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return sut
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
    
    private func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(),
                               statusCode: 200,
                               httpVersion: nil,
                               headerFields: nil)!
    }
    private func anyURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(),
                           mimeType: nil,
                           expectedContentLength: 0,
                           textEncodingName: nil)
    }
    
    private func resultOnError(data: Data?,
                               response: URLResponse?,
                               error: NSError?,
                               file: StaticString = #file,
                               line: UInt = #line) -> NSError? {
        let result = resultFor(data: data,
                               response: response,
                               error: error,
                               file: file,
                               line: line)
        switch result {
        case .failure(let error):
            return error as NSError
        default:
            XCTFail("Expect failure but instead got \(result)",
                    file: file,
                    line: line)
            return nil
        }
    }
    
    private func resultValuesFor(data: Data?,
                                 response: URLResponse?,
                                 error: NSError?,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> (data: Data, httpResponse: HTTPURLResponse)? {
        let result = resultFor(data: data,
                               response: response,
                               error: error,
                               file: file,
                               line: line)
        switch result {
        case let .success(data, httpURLResponse):
            return (data, httpURLResponse)
        default:
            XCTFail("Expect success but instead got \(result)",
                    file: file,
                    line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?,
                           response: URLResponse?,
                           error: NSError?,
                           file: StaticString = #file,
                           line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        var capturedValue: HTTPClientResult!
        let exp = expectation(description: "wait for completion")
        let sut = makeSUT(file: file, line: line)
        sut.get(from: anyURL()) { result in
            capturedValue = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedValue
    }
    
    private class URLProtocolStub: URLProtocol {
        private(set) static var stub: Stub? = nil
        private static var requestObserver: ((URLRequest) -> Void)?
        
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error? = nil) {
                stub = Stub(data: data,
                            response: response,
                            error: error)
            }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let stub = URLProtocolStub.stub {
                if let data = stub.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                
                if let response = stub.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                
                if let error = stub.error {
                    client?.urlProtocol(self, didFailWithError: error)
                }
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
