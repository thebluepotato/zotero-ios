//
//  ApiLogger.swift
//  Zotero
//
//  Created by Michal Rentka on 05.03.2021.
//  Copyright © 2021 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import CocoaLumberjackSwift

struct ApiLogger {
    static func identifier(method: String, url: String) -> String {
        return "HTTP (\(method)) \(url)"
    }

    static func log(request: ApiRequest, url: URL?) -> String {
        let identifier = ApiLogger.identifier(method: request.httpMethod.rawValue, url: url?.absoluteString ?? request.debugUrl)
        DDLogInfo(identifier)
        if request.encoding != .url, let params = request.parameters {
            DDLogDebug("\(request.redact(parameters: params))")
        }
        return identifier
    }

    static func log(result: Result<(HTTPURLResponse, Data), Error>, identifier: String, request: ApiRequest) {
        switch result {
        case .failure(let error):
            DDLogInfo("\(identifier) failed - \(error)")

        case .success((let response, let data)):
            DDLogInfo("\(identifier) succeeded with \(response.statusCode)")
            #if DEBUG
            if let string = String(data: data, encoding: .utf8) {
                DDLogDebug("\(request.redact(response: string))")
            }
            #endif
        }
    }
}
