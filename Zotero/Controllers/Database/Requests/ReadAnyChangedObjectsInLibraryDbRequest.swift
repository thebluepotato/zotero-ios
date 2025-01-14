//
//  ReadAnyChangedObjectsInLibraryDbRequest.swift
//  Zotero
//
//  Created by Michal Rentka on 03/07/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import RealmSwift

struct ReadAnyChangedObjectsInLibraryDbRequest<Obj: UpdatableObject>: DbResponseRequest {
    typealias Response = Results<Obj>

    let libraryId: LibraryIdentifier

    var needsWrite: Bool { return false }
    var ignoreNotificationTokens: [NotificationToken]? { return nil }

    func process(in database: Realm) throws -> Results<Obj> {
        return database.objects(Obj.self).filter(.changesOrDeletions(in: self.libraryId))
    }
}
