/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import SnapKit

// MARK: API
extension BrowserChromeView {
    func showReaderModeBar(animated: Bool = false) {

    }

    func hideReaderModeBar(animated: Bool = false) {

    }

    func showBottomToolbar(animated: Bool = false) {

    }

    func hideBottomToolbar(animated: Bool = false) {

    }
}

class BrowserChromeView: UIView {
    let tab: Browser

    var webView: WKWebView {
        return tab.webView!
    }

    lazy var urlBar: URLBarView = {
        return URLBarView()
    }()

    lazy var readerModeBar: ReaderModeBarView = {
        return ReaderModeBarView()
    }()

    lazy var toolbar: BrowserToolbar = {
        return BrowserToolbar()
    }()

    lazy var snackBarContainer: UIView = {
        return UIView()
    }()

    init(tab: Browser) {
        self.tab = tab
        super.init(frame: CGRectZero)
        addSubview(webView)
        addSubview(readerModeBar)
        addSubview(urlBar)
        addSubview(toolbar)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        urlBar.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(10)
            make.height.equalTo(44)
        }

        toolbar.snp_makeConstraints { make in
            make.height.equalTo(44)
            make.bottom.right.left.equalTo(self)
        }

        webView.snp_makeConstraints { make in
            make.top.equalTo(self.urlBar.snp_bottom)
            make.bottom.equalTo(self.toolbar.snp_top)
            make.left.right.equalTo(self)
        }
    }
}
