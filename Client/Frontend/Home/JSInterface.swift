/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import JavaScriptCore

enum AddonState: Int {
    case Enable = 1
    case Disable = 2
    case Upgrade = 3
    case Downgrade = 4
    case Install = 5
    case Uninstall = 6
}

public class JSInterface: NSObject {
    let jsContext = JSContext()

    let homePanels = AddonHomePanels()
    let homeProvider = HomeProvider()

    //TEMP
    private lazy var bootstrapStruct: String = {
        return self.jsBootstrapStructureWithProperties(
            id: "panel",
            version: "1",
            installPath: "path",
            resourceURI: "uri",
            oldVersion: "0",
            newVersion: "2")
    }()

    override init() {
        super.init()
        defineGlobalsInContext(jsContext)
        jsContext.setObject(homePanels, forKeyedSubscript: "HomePanels")
        jsContext.setObject(homeProvider, forKeyedSubscript: "HomeProvider")
    }

    private func jsBootstrapStructureWithProperties(#id: String, version: String, installPath: String,
                                                    resourceURI: String, oldVersion: String,
                                                    newVersion: String) -> String {
        let structure: [String: String] = [
            "id": id,
            "version": version,
            "installPath": installPath,
            "resourceURI": resourceURI,
            "oldVersion": oldVersion,
            "newVersion": newVersion
        ]
        let data = NSJSONSerialization.dataWithJSONObject(structure, options: NSJSONWritingOptions.allZeros, error: nil)
        return NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
    }

    private func defineGlobalsInContext(context: JSContext) {
        context.globalObject.setValue(AddonState.Enable.rawValue, forProperty: "ADDON_ENABLE")
        context.globalObject.setValue(AddonState.Disable.rawValue, forProperty: "ADDON_DISABLE")
        context.globalObject.setValue(AddonState.Upgrade.rawValue, forProperty: "ADDON_UPGRADE")
        context.globalObject.setValue(AddonState.Downgrade.rawValue, forProperty: "ADDON_DOWNGRADE")
        context.globalObject.setValue(AddonState.Install.rawValue, forProperty: "ADDON_INSTALL")
        context.globalObject.setValue(AddonState.Uninstall.rawValue, forProperty: "ADDON_UNINSTALL")
    }

    private func invokeBootstrapMethod(method: String, data: String, reason: AddonState, withScript url: NSURL) {
        //TODO: Figure out a way to load the addon script into the VM or something so we don't have to execute it everytime.
        var script = NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: nil) as! String
        script += ";\(method)(\(data), \(reason.rawValue))"
        jsContext.evaluateScript(script)
    }

    /**
     * bootstrap.js API
     * https://developer.mozilla.org/en-US/Add-ons/Bootstrapped_extensions
     */
    public func installAddonUsingScript(url: NSURL) {
        invokeBootstrapMethod("install", data: bootstrapStruct, reason: AddonState.Install, withScript: url)
    }

    public func uninstallAddonUsingScript(url: NSURL) {
        invokeBootstrapMethod("uninstall", data: bootstrapStruct, reason: AddonState.Uninstall, withScript: url)
    }

    public func startupAddonUsingScript(url: NSURL) {
        invokeBootstrapMethod("startup", data: bootstrapStruct, reason: AddonState.Enable, withScript: url)
    }

    public func shutdownAddonUsingScript(url: NSURL) {
        invokeBootstrapMethod("shutdown", data: bootstrapStruct, reason: AddonState.Disable, withScript: url)
    }
}
