/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private struct SettingsPListKeys {
    static let DefaultValueKey      = "Default Value"
    static let PreferenceItemsKey   = "Preference Items"
    static let IdentifierKey        = "Identifier"
}

enum AppConfigurationError {
    case FailedToLoadSettingsBundle
}

extension AppConfigurationError: MaybeErrorType {
    var description: String {
        switch (self) {
        case .FailedToLoadSettingsBundle: return "Unable to load Settings bundle Root.plist file."
        }
    }
}

struct AppConfiguration {

    private let userDefaults: NSUserDefaults

    private let ioQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

    init(userDefaults: NSUserDefaults) {
        self.userDefaults = userDefaults
    }
}

// MARK: - Settings Configuration Helpers
extension AppConfiguration {
    func registerDefaultsFromSettingsBundleIfAvailable() -> Success {
        return loadSettingsBundleDictionary() >>== { settings in

            // Register defualts for toggle items with boolean value
            //SettingsBundleKey.allToggleKeys.forEach { key in
            //    self.assignDefaultBoolValueForSettingKey(key, fromSettings: settings)
            //}

            return succeed()
        }
    }

    private func assignDefaultBoolValueForSettingKey(key: String, fromSettings settings: NSDictionary) {
        if let item = findItemWithIdentifier(key, inSettings: settings) {
            let defaultValue = (item[SettingsPListKeys.DefaultValueKey] as? Bool) ?? false
            userDefaults.setBool(defaultValue, forKey: key)
        }
    }

    private func findItemWithIdentifier(identifier: String, inSettings settings: NSDictionary) -> NSDictionary? {
        if let preferenceItems = settings[SettingsPListKeys.PreferenceItemsKey] as? [NSDictionary] {
            return preferenceItems.filter { ($0[SettingsPListKeys.IdentifierKey] as? String) == identifier } .first
        }
        return nil
    }

    private func loadSettingsBundleDictionary() -> Deferred<Maybe<NSDictionary>> {
        return deferDispatchAsync(ioQueue) {
            guard let filename = NSBundle.mainBundle().pathForResource("Settings", ofType: "bundle"),
                let settings = NSDictionary(contentsOfFile: filename.stringByAppendingString("/Root.plist")) else {
                    return deferMaybe(AppConfigurationError.FailedToLoadSettingsBundle)
            }
            return deferMaybe(settings)
        }
    }

    private func settingsBundleAvailable() -> Bool {
        return NSBundle.mainBundle().pathForResource("Settings", ofType: "bundle") != nil
    }
}

// MARK: - Configuration Methods
extension AppConfiguration {

    var shouldRestoreTabs: Bool {
        return true
//        if settingsBundleAvailable() {
//            return NSUserDefaults.standardUserDefaults().boolForKey(SettingsBundleKey.TabRestoration)
//        } else {
//            return true
//        }
    }
}

// MARK: AppDelegate Singleton
extension AppConfiguration {

    static var sharedInstance: AppConfiguration {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.configuration
    }
}