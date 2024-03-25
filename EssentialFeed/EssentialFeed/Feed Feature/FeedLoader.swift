//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Jastin on 18/9/23.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
