//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 16/9/23.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = self.makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load {_ in }
        XCTAssertEqual([url], client.requestedURLs)
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load {_ in }
        sut.load {_ in }
        XCTAssertEqual([url, url], client.requestedURLs)
        XCTAssertEqual(2, client.requestedURLs.count)
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = self.makeSUT()
        expect(sut, toCompleteWith: failure(.connectivity)) {
            let clientError = NSError(domain: "Error", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNonHTTPResponse() {
        let (sut, client) = self.makeSUT()
        let invalidCodeSamples = [199, 201, 300, 400, 500]
        invalidCodeSamples.enumerated().forEach { index, value in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let json = self.makeItemsJSON([])
                client.complete(withStatusCode: value,
                                data: json,
                                at: index)
            }
        }
    }
    
    func test_load_deliversErrorsOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = self.makeSUT()
        expect(sut, toCompleteWith: failure(.invalidData)) {
            let invalidJSON = Data("invalidJSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = self.makeSUT()
        expect(sut, toCompleteWith: .success([])) {
            let emtyListJSON = self.makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emtyListJSON)
        }
    }
    
    func test_load_deliverItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = self.makeSUT()
        
        let item1 = makeItem(id: UUID(),
                             imageURL: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "http://another-url.com")!)
        let items = [item1.item, item2.item]
        expect(sut, toCompleteWith: .success(items)) {
            let itemsJSON = [item1.JSON, item2.JSON]
            let json = self.makeItemsJSON(itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://a-given-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var captureResults = [RemoteFeedLoader.Result]()
        sut?.load(completion: { captureResults.append($0) })
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(captureResults.isEmpty)
    }
    
    //   MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        trackForMemoryLeaks(instance: client, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith expectedResult: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        
        let expect = expectation(description: "wair for load to completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedData), .success(let expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            expect.fulfill()
        }
        
        action()
        
        wait(for: [expect], timeout: 1.0)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private func makeItem(id: UUID,
                          description: String? = nil,
                          location: String? = nil,
                          imageURL: URL) -> (item: FeedItem, JSON: [String: Any]) {
        
        let item = FeedItem(id: id,
                            description: description,
                            location: location,
                            imageURL: imageURL)
        
        let itemJSON = ["id": item.id.uuidString,
                        "description": item.description,
                        "location": item.location,
                        "image": item.imageURL.absoluteString]
            .reduce(into: [String: Any]()) { acc, keyPair in
                if let value = keyPair.value {
                    acc[keyPair.key] = value
                }
            }
        
        return (item, itemJSON)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private class HTTPClientSpy: HTTPClient {
        
        private (set) var messages =  [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return self.messages.map({ $0.url })
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            self.messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            self.messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let url = self.requestedURLs[index]
            let response = HTTPURLResponse(url: url,
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            self.messages[index].completion(.success(data, response))
        }
    }
}
