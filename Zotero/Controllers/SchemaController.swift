//
//  SchemaController.swift
//  Zotero
//
//  Created by Michal Rentka on 08/04/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import CocoaLumberjack
import RxSwift

protocol SchemaDataSource: class {
    var itemTypes: [String] { get }

    func fields(for type: String) -> [FieldSchema]?
    func creators(for type: String) -> [CreatorSchema]?
    func titleKey(for type: String) -> String?
    func localized(itemType: String) -> String?
    func localized(field: String) -> String?
    func localized(creator: String) -> String?
}

class SchemaController {
    private let apiClient: ApiClient
    private let userDefaults: UserDefaults
    private let defaultsDateKey: String
    private let defaultsEtagKey: String
    private let disposeBag: DisposeBag
    private let minReloadInterval: Double

    private(set) var itemSchemas: [String: ItemSchema] = [:]
    private(set) var locales: [String: SchemaLocale] = [:]
    private(set) var version: Int = 0

    init(apiClient: ApiClient, userDefaults: UserDefaults) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
        self.defaultsDateKey = "SchemaControllerLastFetchKey"
        self.defaultsEtagKey = "SchemaControllerEtagKey"
        self.disposeBag = DisposeBag()
        self.minReloadInterval = 86400 // 1 day
    }

    func reloadSchemaIfNeeded() {
        if self.itemSchemas.isEmpty || self.locales.isEmpty {
            self.loadBundledData()
        }
        self.fetchSchemaIfNeeded()
    }

    private func fetchSchemaIfNeeded() {
        let lastFetchTimestamp = self.userDefaults.double(forKey: self.defaultsDateKey)

        if lastFetchTimestamp == 0 {
            self.fetchSchema()
            return
        }

        let lastFetchDate = Date(timeIntervalSince1970: lastFetchTimestamp)
        if Date().timeIntervalSince(lastFetchDate) >= self.minReloadInterval {
            self.fetchSchema()
        }
    }

    private func fetchSchema() {
        self.createFetchSchemaCompletable().observeOn(MainScheduler.instance).subscribe().disposed(by: self.disposeBag)
    }

    func createFetchSchemaCompletable() -> Completable {
        let etag = self.userDefaults.string(forKey: self.defaultsEtagKey)
        return self.apiClient.send(dataRequest: SchemaRequest(etag: etag))
                             .do(onSuccess: { [weak self] (data, headers) in
                                 guard let `self` = self else { return }
                                 self.reloadSchema(from: data)
                                 if let etag = headers["etag"] as? String {
                                     self.userDefaults.set(etag, forKey: self.defaultsEtagKey)
                                 }
                                 self.userDefaults.set(Date().timeIntervalSince1970, forKey: self.defaultsDateKey)
                             }, onError: { error in
                                 if error.isUnchangedError {
                                     return
                                 }

                                 // Don't need to do anything, we've got bundled schema, we've got auto retries
                                 // on backend errors, if everything fails we'll try again on app becoming active
                                 DDLogError("SchemaController: could not fetch schema - \(error)")
                             })
                             .asCompletable()
    }

    private func loadBundledData() {
        guard let schemaPath = Bundle.main.path(forResource: "schema", ofType: "json") else { return }
        let url = URL(fileURLWithPath: schemaPath)
        guard let schemaData = try? Data(contentsOf: url),
              let (etagPart, schemaPart) = self.chunks(from: schemaData, separator: "\r\n\r\n") else { return }
        self.storeEtag(from: etagPart)
        self.reloadSchema(from: schemaPart)
    }

    private func storeEtag(from data: Data) {
        if let etag = self.etag(from: data) {
            self.userDefaults.set(etag, forKey: self.defaultsEtagKey)
        }
    }

    private func reloadSchema(from data: Data) {
        guard let jsonData = try? JSONSerialization.jsonObject(with: data,
                                                               options: .allowFragments) as? [String: Any] else { return }
        let schema = SchemaResponse(data: jsonData)
        self.itemSchemas = schema.itemSchemas
        self.locales = schema.locales
        self.version = schema.version
    }

    private func etag(from data: Data) -> String? {
        guard let headers = String(data: data, encoding: .utf8) else { return nil }

        for line in headers.split(separator: "\r\n") {
            guard line.contains("etag") else { continue }
            let separator = ":"
            let separatorChar = separator[separator.startIndex]
            guard let etag = line.split(separator: separatorChar).last.flatMap(String.init) else { continue }
            return etag.trimmingCharacters(in: CharacterSet(charactersIn: " "))
        }

        return nil
    }

    private func chunks(from data: Data, separator: String) -> (Data, Data)? {
        guard let separatorData = separator.data(using: .utf8) else { return nil }

        let wholeRange = data.startIndex..<data.endIndex
        if let range = data.range(of: separatorData, options: [], in: wholeRange) {
            let first = data.subdata(in: data.startIndex..<range.lowerBound)
            let second = data.subdata(in: range.upperBound..<data.endIndex)
            return (first, second)
        }

        return nil
    }
}

extension SchemaController: SchemaDataSource {
    var itemTypes: [String] {
        return Array(self.itemSchemas.keys)
    }

    func fields(for type: String) -> [FieldSchema]? {
        return self.itemSchemas[type]?.fields
    }

    func titleKey(for type: String) -> String? {
        return self.fields(for: type)?.first(where: { $0.field == FieldKeys.title ||
                                                      $0.baseField == FieldKeys.title })?.field
    }

    func creators(for type: String) -> [CreatorSchema]? {
        return self.itemSchemas[type]?.creatorTypes
    }

    func localized(itemType: String) -> String? {
        let localeId = Locale.autoupdatingCurrent.identifier
        return self.locales[localeId]?.itemTypes[itemType]
    }

    func localized(field: String) -> String? {
        let localeId = Locale.autoupdatingCurrent.identifier
        return self.locales[localeId]?.fields[field]
    }

    func localized(creator: String) -> String? {
        let localeId = Locale.autoupdatingCurrent.identifier
        return self.locales[localeId]?.creatorTypes[creator]
    }
}
