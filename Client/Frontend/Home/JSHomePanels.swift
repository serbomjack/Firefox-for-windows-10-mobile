/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import JavaScriptCore

//MARK: Javascript Interface
@objc protocol JSHomePanels: JSExport {
//    var View: JSPanelViewType { get }
//
    func register(id: String, options: [String:AnyObject])
//    func unregister(id: String)
    func install(id: String)
//    func uninstall(id: String)
    func update(id: String)
//    func setAuthenticated(id: String, isAuthenticated: Bool)
}

@objc protocol JSPanelLayout: JSExport {
    var FRAME: Int { get }
}

@objc protocol JSPanelViewType: JSExport {
    var LIST: Int { get }
    var GRID: Int { get }
}

@objc protocol JSPanelItemType: JSExport {
    var ARTICLE: String { get }
    var IMAGE: String { get }
}

@objc protocol JSPanelItemHandlerType: JSExport {
    var BROWSER: Int { get }
}

//MARK: Swift Implementations
class AddonHomePanels: NSObject, JSHomePanels {
    var View: JSPanelViewType = PanelViewType()

    func register(id: String, options: [String:AnyObject]) {
        println("registered \(id) with options \(options)")
    }

    func unregister(id: String) {
        println("unregister")
    }

    func install(id: String) {
        println("installing \(id)")
    }

    func uninstall(id: String) {
        println("uninstall")
    }

    func update(id: String) {
        println("update")
    }

    func setAuthenticated(id: String, isAuthenticated: Bool) {
        println("setAuthenticated")
    }
}

class PanelLayout: NSObject, JSPanelLayout {
    var FRAME = 1
}

class PanelViewType: NSObject, JSPanelViewType {
    var LIST = 1
    var GRID = 2
}

class PanelItemType: NSObject, JSPanelItemType {
    var ARTICLE = "Article"
    var IMAGE = "Image"
}

class PanelItemHandlerType: NSObject, JSPanelItemHandlerType {
    var BROWSER = 1
}

//enum PanelLayout: Int {
//    case Frame = 1
//}
//
//enum PanelViewType: Int {
//    case List = 1
//    case Grid = 2
//}
//
//enum PanelItemType: String {
//    case Article = "Article"
//    case Image = "Image"
//}
//
//enum PanelItemHandlerType: Int {
//    case Browser = 1
//}
