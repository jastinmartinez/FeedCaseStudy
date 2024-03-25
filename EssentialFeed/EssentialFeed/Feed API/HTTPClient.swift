//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Jastin on 25/9/23.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
