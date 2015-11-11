/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Shared
@testable import Client

class AppConfigurationTests: XCTestCase {
    var mockDefaults: NSUserDefaults!
    var config: AppConfiguration!

    override func setUp() {
        super.setUp()
        mockDefaults = NSUserDefaults()
        config = AppConfiguration(userDefaults: mockDefaults)
    }

    func testSharedConfigurationSetInAppDelegate() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let configuration = appDelegate.configuration
        XCTAssertNotNil(configuration)
        XCTAssertNotNil(AppConfiguration.sharedInstance)
    }


    override func tearDown() {
        super.tearDown()
    }
}

