//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Jastin on 18/9/23.
//

import Foundation


public protocol FeedLoader {
    
    typealias Result = Swift.Result<[FeedImage], Error>

    func load(completion: @escaping (Result) -> Void)
}
