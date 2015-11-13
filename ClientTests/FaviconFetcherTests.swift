/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class FaviconFetcherTests: XCTestCase {
    func testSoundcloud() {
        let page = "https://m.soundcloud.com/".asURL!
        let profile = MockProfile()
        let fetcher = FaviconFetcher()
        let icons = fetcher.loadFavicons(page, profile: profile).value.successValue
        XCTAssertNotNil(icons)
        XCTAssertTrue(icons!.count > 1)
    }
}