//
//  MarkObjectsAsSyncedDbRequest.swift
//  Zotero
//
//  Created by Michal Rentka on 11/03/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import RealmSwift

struct MarkObjectsAsSyncedDbRequest<Obj: UpdatableObject&Syncable>: DbRequest {
    let libraryId: LibraryIdentifier
    let keys: [String]
    let version: Int

    var needsWrite: Bool { return true }
    var ignoreNotificationTokens: [NotificationToken]? { return nil }

    func process(in database: Realm) throws {
        let objects = database.objects(Obj.self).filter(.keys(self.keys, in: self.libraryId))
        objects.forEach { object in
            if object.version != self.version {
                object.version = self.version
            }
            object.resetChanges()
        }
    }
}

struct MarkSettingsAsSyncedDbRequest: DbRequest {
    let settings: [(String, LibraryIdentifier)]
    let version: Int

    var needsWrite: Bool { return true }
    var ignoreNotificationTokens: [NotificationToken]? { return nil }

    func process(in database: Realm) throws {
        for setting in self.settings {
            guard let object = database.objects(RPageIndex.self).filter(.key(setting.0, in: setting.1)).first else { continue }
            if object.version != self.version {
                object.version = self.version
            }
            object.resetChanges()
        }
    }
}
