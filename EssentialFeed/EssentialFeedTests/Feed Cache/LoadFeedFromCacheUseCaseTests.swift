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
        let retrievalError = anyNSError()
      
        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeWithEmptyCache()
        }
    }
    
    func test_load_deliverCacheImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetrieval(with: feed.locals, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_deliverNoCacheImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.locals, timestamp: sevenDaysOldTimestamp)
        }
    }
    
    func test_load_deliverNoCacheImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.locals, timestamp: moreThanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_hasNoSideEffectOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load(completion: {_ in })
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load(completion: {_ in })
        store.completeWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnLessThanSevenDayOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
     

        sut.load(completion: {_ in })
        store.completeRetrieval(with: feed.locals, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnSevenDayOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDays = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
     

        sut.load(completion: {_ in })
        store.completeRetrieval(with: feed.locals, timestamp: sevenDays)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnMoreThanSevenDayOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDays = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
     
        sut.load(completion: {_ in })
        store.completeRetrieval(with: feed.locals, timestamp: moreThanSevenDays)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        
        var localFeedLoader: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var loadResults = [LocalFeedLoader.LoadResult]()
        localFeedLoader?.load(completion: { loadResults.append($0) } )
        
        localFeedLoader = nil
        store.completeWithEmptyCache()
        
        XCTAssertTrue(loadResults.isEmpty)
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
    
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation(description: "wait for load")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
}

