//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Jastin on 9/10/23.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
   
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    private(set) var deletions = [DeletionCompletion]()
    private(set) var insertions = [InsertionCompletion]()
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
        deletions[index](error)
    }
    
    func  completeDeletionSuccessfully(at index: Int = 0) {
        deletions[index](nil)
    }
    
    func  completeInsertionSuccessfully(at index: Int = 0) {
        insertions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertions[index](error)
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(items, timestamp))
        insertions.append(completion)
    }
    
    func retrieve() {
        receivedMessages.append(.retrieve)
    }
}
