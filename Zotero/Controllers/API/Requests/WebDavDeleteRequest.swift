//
//  WebDavDeleteRequest.swift
//  Zotero
//
//  Created by Michal Rentka on 12.10.2021.
//  Copyright © 2021 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

struct WebDavDeleteRequest: ApiRequest {
    let endpoint: ApiEndpoint
    let httpMethod: ApiHttpMethod
    let parameters: [String : Any]?
    let encoding: ApiParameterEncoding
    let headers: [String : String]?
    let acceptableStatusCodes: Set<Int>
    let logParams: ApiLogParameters

    init(url: URL, logParams: ApiLogParameters = []) {
        self.endpoint = .webDav(url)
        self.httpMethod = .delete
        self.parameters = nil
        self.encoding = .url
        self.headers = nil
        self.acceptableStatusCodes = [200, 204, 404]
        self.logParams = logParams
    }

    init(endpoint: ApiEndpoint, logParams: ApiLogParameters = []) {
        self.endpoint = endpoint
        self.httpMethod = .delete
        self.parameters = nil
        self.encoding = .url
        self.headers = nil
        self.acceptableStatusCodes = [200, 204, 404]
        self.logParams = logParams
    }
}

