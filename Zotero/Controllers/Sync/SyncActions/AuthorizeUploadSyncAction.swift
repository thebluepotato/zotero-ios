//
//  AuthorizeUploadSyncAction.swift
//  Zotero
//
//  Created by Michal Rentka on 30/01/2020.
//  Copyright © 2020 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import RxSwift

struct AuthorizeUploadSyncAction: SyncAction {
    typealias Result = AuthorizeUploadResponse

    let key: String
    let filename: String
    let filesize: UInt64
    let md5: String
    let mtime: Int
    let libraryId: LibraryIdentifier
    let userId: Int
    let oldMd5: String?

    unowned let apiClient: ApiClient
    let queue: DispatchQueue
    let scheduler: SchedulerType

    var result: Single<AuthorizeUploadResponse> {
        let request = AuthorizeUploadRequest(libraryId: self.libraryId, userId: self.userId, key: self.key, filename: self.filename,
                                             filesize: self.filesize, md5: self.md5, mtime: self.mtime, oldMd5: self.oldMd5)
        return self.apiClient.send(request: request, queue: self.queue)
                             .observe(on: self.scheduler)
                             .flatMap { (data, _) -> Single<AuthorizeUploadResponse> in
                                do {
                                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                                    let response = try AuthorizeUploadResponse(from: jsonObject)
                                    return Single.just(response)
                                } catch {
                                    return Single.error(error)
                                }
                             }
    }
}
