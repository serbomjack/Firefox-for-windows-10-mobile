/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import XCTest

class FileAccessorTests: XCTestCase {
    private var testDir: String!
    private var files: FileAccessor!

    override func setUp() {
        let docPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        files = FileAccessor(rootPath: docPath.stringByAppendingPathComponent("filetest"))

        do {
            testDir = try files.getAndEnsureDirectory()
        } catch _ {
            testDir = nil
        }
        do {
            try files.removeFilesInDirectory()
        } catch _ {
        }
    }

    func testFileAccessor() {
        // Test existence.
        XCTAssertFalse(files.exists("foo"), "File doesn't exist")
        createFile("foo")
        XCTAssertTrue(files.exists("foo"), "File exists")

        // Test moving.
        var success: Bool
        do {
            try files.move("foo", toRelativePath: "bar")
            success = true
        } catch _ {
            success = false
        }
        XCTAssertTrue(success, "Operation successful")
        XCTAssertFalse(files.exists("foo"), "Old doesn't exist")
        XCTAssertTrue(files.exists("bar"), "New file exists")

        do {
            try files.move("bar", toRelativePath: "foo/bar")
            success = true
        } catch _ {
            success = false
        }
        XCTAssertFalse(files.exists("bar"), "Old doesn't exist")
        XCTAssertTrue(files.exists("foo/bar"), "New file exists")

        // Test removal.
        XCTAssertTrue(files.exists("foo"), "File exists")
        do {
            try files.remove("foo")
            success = true
        } catch _ {
            success = false
        }
        XCTAssertTrue(success, "Operation successful")
        XCTAssertFalse(files.exists("foo"), "File removed")

        // Test directory creation and path.
        XCTAssertFalse(files.exists("foo"), "Directory doesn't exist")
        let path = try! files.getAndEnsureDirectory(relativeDir: "foo")
        var isDirectory = ObjCBool(false)
        NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
        XCTAssertTrue(isDirectory, "Directory exists")
    }

    private func createFile(filename: String) {
        let path = testDir.stringByAppendingPathComponent(filename)
        let success: Bool
        do {
            try "foo".writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
            success = true
        } catch _ {
            success = false
        }
        XCTAssertTrue(success, "Wrote to \(path)")
    }
}