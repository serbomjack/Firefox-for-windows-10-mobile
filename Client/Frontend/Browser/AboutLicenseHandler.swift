/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

struct AboutLicenseHandler {
    static func register(webServer: WebServer) {
        webServer.registerHandlerForMethod("GET", module: "about", resource: "license") { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            let path = NSBundle.mainBundle().pathForResource("Licenses", ofType: "html")
            if let html = NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil) as? String {
                return GCDWebServerDataResponse(HTML: html)
            }
            return GCDWebServerResponse(statusCode: 200)
        }
    }

    static func isAboutLicenseURL(url: NSURL) -> Bool {
        if let scheme = url.scheme, host = url.host, path = url.path {
            return scheme == "http" && host == "localhost" && path == "/about/license"
        }
        return false
    }
}