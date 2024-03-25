//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Jastin on 28/9/23.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedErrorValue: Error { }
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        self.session.dataTask(with: url) { data, response, error in
            completion(Result{
                if let error = error {
                    throw error
                } else if let data, let httpResponse = response as? HTTPURLResponse {
                    return (data, httpResponse)
                } else {
                    throw UnexpectedErrorValue()
                }
            })
        }.resume()
    }
}
