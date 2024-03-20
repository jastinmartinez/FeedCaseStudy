//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Jastin on 20/3/24.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
    
    public init() { }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
    
}
