//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Jastin on 9/10/23.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    
    typealias DeletionCompletion = (FeedStore.DeletionResult) -> Void
    typealias InsertionCompletion = (FeedStore.InsertionResult) -> Void
    typealias RetrievalCompletion = (FeedStore.RetrievalResult) -> Void
    
    private(set) var deletions = [DeletionCompletion]()
    private(set) var insertions = [InsertionCompletion]()
    private(set) var retrievals = [RetrievalCompletion]()
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case retrieve
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletions[index](.failure(error))
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletions[index](.success(()))
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertions[index](.success(()))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertions[index](.failure(error))
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(items, timestamp))
        insertions.append(completion)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievals.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievals[index](.failure(error))
    }
    
    func completeWithEmptyCache(at index: Int = 0) {
        retrievals[index](.success(.none))
    }
    
    func completeRetrieval(with localFeedImages: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrievals[index](.success((feed: localFeedImages, timestamp: timestamp)))
    }
}
