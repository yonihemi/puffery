//
//  URLSessionRequestFetchingStrategy.swift
//  Puffery
//
//  Created by Valentin Knabel on 21.04.20.
//  Copyright © 2020 Valentin Knabel. All rights reserved.
//

import Combine
import Foundation
import Overture

final class URLSessionRequestFetchingStrategy: RequestFetchingStrategy {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    private func decode<R>(_ endpoint: Endpoint<R>, request: URLRequest, data: Data?, response: URLResponse?, receive: @escaping (Result<R, FetchingError>) -> Void) {
        switch (data, response as? HTTPURLResponse) {
        case let (data, urlResponse?) where urlResponse.statusCode >= 400:
            let error = FetchingError(reason: .statusCode(urlResponse.statusCode), request: request, data: data)
            endpoint.report(error)
            receive(.failure(error))
        case let (data, _):
            do {
                receive(.success(try endpoint.decode(data)))
            } catch {
                let error = FetchingError(reason: .decoding(error), request: request, data: data)
                endpoint.report(error)
                receive(.failure(error))
            }
        }
    }

    @discardableResult
    func task<R>(_ endpoint: Endpoint<R>, receive: @escaping (Result<R, FetchingError>) -> Void) -> URLSessionDataTask? {
        let receive = { result in
            DispatchQueue.main.async { receive(result) }
        }
        do {
            let request = try update(URLRequest(url: baseURL), endpoint.encode)
            let task = session.dataTask(with: request) { data, urlResponse, error in
                if let error = error {
                    receive(.failure(FetchingError(reason: .http(error), request: request, data: data)))
                    return
                }
                self.decode(endpoint, request: request, data: data, response: urlResponse, receive: receive)
            }
            task.resume()
            return task
        } catch {
            let error = FetchingError(reason: .encoding(error), request: nil, data: nil)
            endpoint.report(error)
            receive(.failure(error))
            return nil
        }
    }

    func publisher<R>(_ endpoint: Endpoint<R>) -> AnyPublisher<R, FetchingError> {
        do {
            let request = try update(URLRequest(url: baseURL), endpoint.encode)
            return try session.dataTaskPublisher(for: update(URLRequest(url: baseURL), endpoint.encode))
                .mapError { urlError in
                    FetchingError(reason: .http(urlError), request: request, data: nil)
                }
                .flatMap { dataAndResponse in
                    Future { next in
                        self.decode(endpoint, request: request, data: dataAndResponse.data, response: dataAndResponse.response, receive: next)
                    }
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: FetchingError(reason: .encoding(error), request: nil, data: nil))
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }
}
