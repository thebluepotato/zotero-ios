//
//  LibrariesStore.swift
//  Zotero
//
//  Created by Michal Rentka on 11/02/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import RealmSwift
import RxSwift

struct LibraryCellData {
    let identifier: Int
    let name: String

    init(identifier: Int, name: String) {
        self.identifier = identifier
        self.name = name
    }

    init(object: RLibrary) {
        self.identifier = object.identifier
        self.name = object.name
    }

    static var myLibrary: LibraryCellData {
        return LibraryCellData(identifier: RLibrary.myLibraryId, name: "My Library")
    }
}

enum LibrariesAction {
    case load
}

enum LibrariesStoreError: Equatable {
    case cantLoadData
}

struct LibrariesState {
    fileprivate(set) var myLibrary: LibraryCellData
    fileprivate(set) var groupLibraries: [LibraryCellData]
    fileprivate(set) var error: LibrariesStoreError?

    // To avoid comparing the whole cellData arrays in == function, we just have a version which we increment
    // on each change and we'll compare just versions of cellData.
    fileprivate var version: Int
    fileprivate var libraries: Results<RLibrary>?
    fileprivate var librariesToken: NotificationToken?

    init() {
        self.myLibrary = LibraryCellData.myLibrary
        self.groupLibraries = []
        self.version = 0
    }
}

extension LibrariesState: Equatable {
    static func == (lhs: LibrariesState, rhs: LibrariesState) -> Bool {
        return lhs.error == rhs.error && lhs.version == rhs.version
    }
}

class LibrariesStore: Store {
    typealias Action = LibrariesAction
    typealias State = LibrariesState

    let dbStorage: DbStorage

    var updater: StoreStateUpdater<LibrariesState>

    init(dbStorage: DbStorage) {
        self.dbStorage = dbStorage
        self.updater = StoreStateUpdater(initialState: LibrariesState())
    }

    func handle(action: LibrariesAction) {
        switch action {
        case .load:
            self.loadData()
        }
    }

    private func reload(libraries: Results<RLibrary>) -> (LibraryCellData?, [LibraryCellData]) {
        guard libraries.count > 0 else { return (nil, []) }
        var groupLibraries = Array(libraries.map(LibraryCellData.init))
        let myLibrary = groupLibraries.removeFirst()
        return (myLibrary, groupLibraries)
    }

    private func loadData() {
        do {
            let libraries = try self.dbStorage.createCoordinator().perform(request: ReadAllLibrariesDbRequest())
            let librariesToken = libraries.observe({ [weak self] changes in
                guard let `self` = self else { return }
                switch changes {
                case .update(let objects, _, _, _):
                    let cellData = self.reload(libraries: objects)
                    self.updater.updateState(action: { newState in
                        if let library = cellData.0 {
                            newState.myLibrary = library
                        }
                        newState.groupLibraries = cellData.1
                        newState.version += 1
                    })
                case .initial: break
                case .error(let error):
                    // TODO: - Log error?
                    self.updater.updateState { newState in
                        newState.error = .cantLoadData
                    }
                }
            })

            let cellData = self.reload(libraries: libraries)
            self.updater.updateState { newState in
                newState.libraries = libraries
                newState.version += 1
                if let library = cellData.0 {
                    newState.myLibrary = library
                }
                newState.groupLibraries = cellData.1
                newState.librariesToken = librariesToken
            }
        } catch let error {
            // TODO: - Log error?
            self.updater.updateState { newState in
                newState.error = .cantLoadData
            }
        }
    }
}