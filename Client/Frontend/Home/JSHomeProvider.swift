/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import JavaScriptCore

//MARK: Javascript Interface
@objc protocol JSHomeStorageItem: JSExport {
    var url: String? { get }
    var title: String? { get }
    var descriptionText: String? { get }
    var imageUrl: String? { get }
    var filter: String? { get }
}

@objc protocol JSHomeStorage: JSExport {
    var items: [JSHomeStorageItem] { get }
    func save(items: [JSHomeStorageItem])
    func deleteAll()
}

@objc protocol JSHomeProvider: JSExport {
    func getStorage(datasetId: String) -> String
    func requestSync(datasetId: String, callback: String)
    func addPeriodicSync(datasetId: String, callback: String)
    func removePeriodicSync(datasetId: String)
}

//MARK: Swift Implementation
class HomeStorageItem: NSObject, JSHomeStorageItem {
    var url: String?
    var title: String?
    var descriptionText: String?
    var imageUrl: String?
    var filter: String?
}

class HomeStorage: NSObject, JSHomeStorage {
    var items: [JSHomeStorageItem] = []

    func save(items: [JSHomeStorageItem]) {
        println("save")
    }

    func deleteAll() {
        println("deleteAll")
    }
}

class HomeProvider: NSObject, JSHomeProvider {
    func getStorage(datasetId: String) -> String {
        println("getStorage")
        return "storage"
    }

    func requestSync(datasetId: String, callback: String) {
        println("requestSync")
    }

    func addPeriodicSync(datasetId: String, callback: String) {
        println("addPeriodicSync")
    }

    func removePeriodicSync(datasetId: String) {
        println("removePeriodicSync")
    }
}