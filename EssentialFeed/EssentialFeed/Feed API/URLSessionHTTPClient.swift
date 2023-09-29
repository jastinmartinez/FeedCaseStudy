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
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        self.session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data, let httpResponse = response as? HTTPURLResponse {
                completion(.success(data, httpResponse))
            } else {
                completion(.failure(UnexpectedErrorValue()))
            }
        }.resume()
    }
}
