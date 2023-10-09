//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Jastin on 18/9/23.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
