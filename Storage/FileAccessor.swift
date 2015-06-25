/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * A convenience class for file operations under a given root directory.
 * Note that while this class is intended to be used to operate only on files
 * under the root, this is not strictly enforced: clients can go outside
 * the path using ".." or symlinks.
 */
public class FileAccessor {
    public let rootPath: String

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    /**
     * Gets the absolute directory path at the given relative path, creating it if it does not exist.
     */
    public func getAndEnsureDirectory(relativeDir: String? = nil) throws -> String {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        var absolutePath = rootPath

        if let relativeDir = relativeDir {
            absolutePath = absolutePath.stringByAppendingPathComponent(relativeDir)
        }

        if var value = createDir(absolutePath) ? absolutePath : nil {
            return value
        }
        throw error
    }

    /**
     * Gets the file or directory at the given path, relative to the root.
     */
    public func remove(relativePath: String) throws {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        try NSFileManager.defaultManager().removeItemAtPath(path)
    }

    /**
     * Removes the contents of the directory without removing the directory itself.
     */
    public func removeFilesInDirectory(relativePath: String = "") throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        let fileManager = NSFileManager.defaultManager()
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(path)
            var success = true
            for file in files {
                if let filename = file as? String {
                    success = success && remove(relativePath.stringByAppendingPathComponent(filename))
                }
            }
            if success {
                return
            }
            # /* TODO: Finish migration: rewrite code to move the next statement out of enclosing do/catch */
            throw error
        } catch var error1 as NSError {
            error = error1
        }

        throw error
    }

    /**
     * Determines whether a file exists at the given path, relative to the root.
     */
    public func exists(relativePath: String) -> Bool {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

    /**
     * Moves the file or directory to the given destination, with both paths relative to the root.
     * The destination directory is created if it does not exist.
     */
    public func move(fromRelativePath: String, toRelativePath: String) throws {
        let fromPath = rootPath.stringByAppendingPathComponent(fromRelativePath)
        let toPath = rootPath.stringByAppendingPathComponent(toRelativePath)
        let toDir = toPath.stringByDeletingLastPathComponent

        try createDir(toDir)

        try NSFileManager.defaultManager().moveItemAtPath(fromPath, toPath: toPath)
    }

    /**
     * Creates a directory with the given path, including any intermediate directories.
     * Does nothing if the directory already exists.
     */
    private func createDir(absolutePath: String) throws {
        try NSFileManager.defaultManager().createDirectoryAtPath(absolutePath, withIntermediateDirectories: true, attributes: nil)
    }
}
