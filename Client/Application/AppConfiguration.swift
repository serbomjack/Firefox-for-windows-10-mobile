/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 *  App-wide configuration settings that pull in from Settings bundle if available.
 */
struct AppConfiguration {

    private static var settingsDictionary: NSDictionary?

    private static var registrationCalled: Bool = false

    /**
     Should be called on app startup to register default values from the Settings bundle if available.
     */
    static func registerDefaultsFromSettingsBundleIfAvailable() {
        assert(!registrationCalled, "registerDefaultsFromSettingsBundleIfAvailable should only be called once.")

        settingsDictionary = settingsBundleDictionary()

        // Register defualts for toggle items with boolean value
        SettingsBundleKey.allToggleKeys.forEach(assignDefaultBoolValueForSettingKey)

        registrationCalled = true
    }

    /**
     Pulls out the default value key for a Settings item and assigns the boolean to NSUserDefaults.

     - parameter key: Settings identifier key to use the default value for.
     */
    private static func assignDefaultBoolValueForSettingKey(key: String) {
        if let item = findItemWithIdentifier(key) {
            let defaultValue = (item["Default Value"] as? Bool) ?? false
            NSUserDefaults.standardUserDefaults().setBool(defaultValue, forKey: key)
        }
    }

    /**
     Finds the settings item with the given identifier.

     - parameter identifier: Settings item identifier string.

     - returns: NSDictionary containing item information from Root.plist
     */
    private static func findItemWithIdentifier(identifier: String) -> NSDictionary? {
        if let preferenceItems = settingsDictionary?["Preference Items"] as? [NSDictionary] {
            return preferenceItems.filter { ($0["Identifier"] as? String) == identifier } .first
        }
        return nil
    }

    /**
     Loads the Setting bundle's root plist file.

     - returns: Root.plist data in a NSDictionary if found.
     */
    private static func settingsBundleDictionary() -> NSDictionary? {
        let filename = NSBundle.mainBundle().pathForResource("Settings", ofType: "bundle")
        if let filename = filename {
           return NSDictionary(contentsOfFile: filename.stringByAppendingString("/Root.plist"))
        } else {
            return nil
        }
    }

    /**
     Checks to see if there is a Settings bundle available.

     - returns: True if settings bundle exists, false otherwise.
     */
    private static func settingsBundleAvailable() -> Bool {
        return NSBundle.mainBundle().pathForResource("Settings", ofType: "bundle") != nil
    }

    /**
     Assert that registration has been called.
     */
    private static func checkRegisterWasCalled() {
        assert(registrationCalled, "registerDefaultsFromSettingsBundleIfAvailable MUST be called before asking for configuration settings.")
    }
}

// MARK: - Configuration Methods
extension AppConfiguration {

    /**
     Determines if we should restore tabs on startup or not. Configurable by settings bundle.

     - returns: True/false if tabs should be restored. Defualts to true if not configured.
     */
    static func shouldRestoreTabs() -> Bool {
        checkRegisterWasCalled()

        if settingsBundleAvailable() {
            return NSUserDefaults.standardUserDefaults().boolForKey(SettingsBundleKey.TabRestoration)
        } else {
            return true
        }
    }
}