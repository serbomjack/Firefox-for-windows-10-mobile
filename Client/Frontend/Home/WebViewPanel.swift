/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import WebKit
import Storage

/**
 Data API accessibile to pages inside a WebViewPanel

 - GetBookmarkModelForID: Returns the bookmark model for the given GUID
 - GetRootBookmarkFolder: Returns the root bookmark model
 - getSitesByLastVisit:   Returns history items ordered by last visit
 - getTopSites:           Returns top sites ordered by frecency limited to the given limit
 - getClientsAndTabs:     Returns all cached remote clients and tabs
 - Undefined:             Default case for any message not recognized
 */
private enum DataMethod: String {

    /*
    GetBookmarkModelForID
        {
            method: "getBookmarkModelForID",
            params: {
                id: <String>
            },
            callback: <CallbackFunc>
        }
    */
    case GetBookmarkModelForID      = "getBookmarkModelForID"

    /* 
    GetRootBookmarkFolder
        {
            method: "getBookmarkModelForID",
            callback: <CallbackFunc>
        }
    */
    case GetRootBookmarkFolder      = "getRootBookmarkFolder"

    /* 
    getSitesByLastVisit
        {
            method: "getSitesByLastVisit",
            params: {
                limit: <Int>
            },
            callback: <CallbackFunc>
        }
    */
    case getSitesByLastVisit        = "getSitesByLastVisit"

    /* 
    getTopSites
        {
            method: "getTopSites",
            params: {
                limit: <Int>
            },
            callback: <CallbackFunc>
        }
    */
    case getTopSites                = "getTopSites"

    /* 
    getClientsAndTabs
        {
            method: "getClientsAndTabs",
            callback: <CallbackFunc>
        }
    */
    case getClientsAndTabs          = "getClientsAndTabs"
    case Undefined
}

class WebPanelDataAPI: NSObject, WKScriptMessageHandler {

    unowned let profile: Profile

    unowned let webView: WKWebView

    init(webView: WKWebView, profile: Profile) {
        self.webView = webView
        self.profile = profile
        super.init()
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let messageDict = message.body as? [String: AnyObject],
              let methodName = messageDict["method"] as? String,
        let params = messageDict["params"] as? [String: AnyObject] else {
            return
        }

        switch (DataMethod(rawValue: methodName) ?? .Undefined) {
        case .GetBookmarkModelForID:
            guard let guid = params["id"] as? String else {
                return
            }

            profile.bookmarks.modelForFolder(guid).uponQueue(dispatch_get_main_queue()) { result in
            }

        case .GetRootBookmarkFolder:
            profile.bookmarks.modelForRoot().uponQueue(dispatch_get_main_queue()) { result in

            }

        case .getSitesByLastVisit:
            guard let limit = params["limit"] as? Int,
                  let callback = messageDict["callback"] as? String else {
                return
            }

            profile.history.getSitesByLastVisit(limit).uponQueue(dispatch_get_main_queue()) { result in
                let callbackInvocation: String
                if let sites = result.successValue {
                    let data = sites.map { $0!.toJSON() }
                    callbackInvocation = "\(callback)(null, \(data))"
                } else {
                    var err = [String: String]()
                    err["message"] = result.failureValue?.description ?? "No description"
                    callbackInvocation = "\(callback)(\(err), null)"
                }

                self.webView.evaluateJavaScript(callbackInvocation, completionHandler: nil)
            }

        case .getTopSites:
            guard let limit = params["limit"] as? Int else {
                return
            }
            profile.history.getTopSitesWithLimit(limit).uponQueue(dispatch_get_main_queue()) { result in
            }

        case .getClientsAndTabs:
            profile.getCachedClientsAndTabs().uponQueue(dispatch_get_main_queue()) { result in

            }
        case .Undefined: break
        }
    }
}

// MARK: JSON extensions to native data objects

protocol JSONView {
    func toJSON() -> [String: String]
}

extension BookmarksModel: JSONView {
    func toJSON() -> [String: String] {
        return [String: String]()
    }
}

extension Site: JSONView {
    func toJSON() -> [String: String] {
        return [
            "title": title,
            "url": url
        ]
    }
}

extension RemoteTab: JSONView {
    func toJSON() -> [String: String] {
        return [String: String]()
    }
}

class WebViewPanel: UIViewController, HomePanel {

    weak var homePanelDelegate: HomePanelDelegate?

    private let url: NSURL
    private let profile: Profile

    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        let dataAPIHandler = WebPanelDataAPI(webView: webView, profile: self.profile)
        webView.configuration.userContentController.addScriptMessageHandler(dataAPIHandler, name: "mozAPI")
        return webView
    }()

    init(profile: Profile, url: String) {
        self.profile = profile
        self.url = url.asURL!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp_makeConstraints { make in
            make.edges.equalTo(view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
}