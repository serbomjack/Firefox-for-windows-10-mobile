/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol WindowHeightHelperDelegate {
    func windowHeightHelper(helper: WindowHeightHelper, didChangeHeight height: CGFloat)
}

class WindowHeightHelper: BrowserHelper {
    var delegate: WindowHeightHelperDelegate?

    static func name() -> String {
        return "WindowHeightHelper"
    }

    required init(browser: Browser) {
        if let path = NSBundle.mainBundle().pathForResource("WindowHeightHelper", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true)
                browser.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "windowHeightMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let height = message.body as? NSNumber {
            delegate?.windowHeightHelper(self, didChangeHeight: CGFloat(height.floatValue))
        }
    }
}