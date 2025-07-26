//
//  RequestLoggerMiddleware.swift
//  Nice
//
//  Created by Harlan Haskins on 5/22/25.
//

import Foundation
import Hummingbird
import Logging

struct RequestLoggerMiddleware<Context: RequestContext>: RouterMiddleware {
    let logger = Logger(label: "HTTP")
    let clock = ContinuousClock()

    func log(
        _ level: Logger.Level = .info,
        prefix: String,
        id: String,
        request: Request,
        start: ContinuousClock.Instant? = nil,
        status: HTTPResponse.Status? = nil,
        suffix: String? = nil
    ) {
        var uri = request.uri.description
        if uri.hasSuffix("?") {
            uri.removeLast()
        }

        var pieces = ["\(prefix)(\(id)): \(request.method.rawValue) \(uri)"]
        if let status {
            pieces.append(status.description)
        }
        if let suffix {
            pieces.append(suffix)
        }
        if let start {
            let end = clock.now
            let interval = end - start
            pieces.append("\(interval)")
        }
        logger.log(level: level, "\(pieces.joined(separator: " - "))")
    }

    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        let shortID = String(UUID().uuidString.prefix(6).lowercased())
        let start = clock.now
        log(prefix: "Request", id: shortID, request: request)
        do {
            let response = try await next(request, context)
            log(prefix: "Response", id: shortID, request: request, start: start, status: response.status)
            return response
        } catch let error as HTTPError {
            log(prefix: "Response", id: shortID, request: request, start: start, status: error.status, suffix: error.body)
            throw error
        } catch {
            log(prefix: "Error", id: shortID, request: request, start: start, status: .internalServerError, suffix: "\(error)")
            throw error
        }
    }
}
