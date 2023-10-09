//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 9/10/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessagesStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load {_ in}
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let exp = expectation(description: "wait for load")
        let retrievalError = anyNSError()
        
        var capturedError: Error?
        sut.load { result in
            switch result {
            case .success:
                XCTFail("expected failure and instead got \(result)")
            case .failure(let error):
                capturedError = error
            }
            exp.fulfill()
        }
        
        store.completeRetrieval(with: retrievalError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as? NSError, retrievalError)
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        let exp = expectation(description: "wait for load")
        
        var capturedFeedImages = [FeedImage]()
        sut.load { result in
            switch result {
            case .success(let feedImages):
                capturedFeedImages = feedImages
            case .failure:
                XCTFail("expected failure and instead got \(result)")
            }
            exp.fulfill()
        }
        store.completeWithEmptyCache()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedFeedImages, [])
    }
    
    //   MARK: Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader,
                                                 store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let localFeedLoader = LocalFeedLoader(store: store,
                                              currentDate: currentDate)
        trackForMemoryLeaks(instance: store, file: file, line: line)
        trackForMemoryLeaks(instance: localFeedLoader, file: file, line: line)
        return (localFeedLoader, store)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
}
