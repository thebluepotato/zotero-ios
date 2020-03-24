//
//  CollectionEditError.swift
//  Zotero
//
//  Created by Michal Rentka on 28/02/2020.
//  Copyright © 2020 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

enum CollectionEditError: Error, Identifiable {
    case saveFailed, emptyName

    var id: CollectionEditError {
        return self
    }
}