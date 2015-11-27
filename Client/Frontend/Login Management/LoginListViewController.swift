/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage

private struct LoginListUX {
    static let RowHeight: CGFloat = 58
    static let SearchHeight: CGFloat = 58
}

class LoginListViewController: UIViewController {

    private var loginDataSource: LoginCursorDataSource?

    private var loginSearchController: LoginSearchController?

    private let profile: Profile

    private lazy var searchView: SearchInputView = {
        let view = SearchInputView()
        return view
    }()

    private lazy var tableView: UITableView = {
        return UITableView()
    }()

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.whiteColor()

        self.title = NSLocalizedString("Logins", comment: "Title for Logins List View screen")
        loginDataSource = LoginCursorDataSource(tableView: self.tableView)
        loginSearchController = LoginSearchController(profile: self.profile, dataSource: loginDataSource!)

        view.addSubview(searchView)
        view.addSubview(tableView)

        searchView.snp_makeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom).constraint
            make.left.right.equalTo(self.view)
            make.height.equalTo(LoginListUX.SearchHeight)
        }

        tableView.snp_makeConstraints { make in
            make.top.equalTo(searchView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.dataSource = loginDataSource
        tableView.delegate = self
        tableView.reloadData()
    }
}

extension LoginListViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Force the headers to be hidden
        return 0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return LoginListUX.RowHeight
    }
}

/// Controller that handles interacts with the search widget and updating the data source for searching
private class LoginSearchController: NSObject, SearchInputViewDelegate {

    private let profile: Profile

    unowned let dataSource: LoginCursorDataSource

    init(profile: Profile, dataSource: LoginCursorDataSource) {
        self.profile = profile
        self.dataSource = dataSource
        super.init()
    }

    @objc func searchInputView(searchView: SearchInputView, didChangeTextTo text: String) {
        print("Search field changed to: \(text)")
    }

    @objc func searchInputViewDidClose(searchView: SearchInputView) {
        print("Closed search mode")
    }

    private func searchLoginsWithText(text: String) {
        profile.logins.getAllLogins().uponQueue(dispatch_get_main_queue()) { logins in
        }
    }
}

/// Data source for handling LoginData objects from a Cursor
private class LoginCursorDataSource: NSObject, UITableViewDataSource {

    unowned let tableView: UITableView

    private let LoginCellIdentifier = "LoginCell"

    var data = [
        Login.createWithHostname("alphabet.com", username: "A@mozilla.com", password: "password1"),
        Login.createWithHostname("amazon.com", username: "AB@mozilla.com", password: "password1"),
        Login.createWithHostname("canada.com", username: "ABC@mozilla.com", password: "password1"),
        Login.createWithHostname("detroit.com", username: "C@mozilla.com", password: "password1"),
        Login.createWithHostname("hannover.com", username: "D@mozilla.com", password: "password1"),
        Login.createWithHostname("zoolander.com", username: "Z@mozilla.com", password: "password1"),
        Login.createWithHostname("zombo.com", username: "ZZ@mozilla.com", password: "password1")
    ]

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        self.tableView.registerClass(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)
    }

    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionIndexTitlesForTableView(tableView)?.count ?? 0
    }

    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loginsForSection(section).count
    }

    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell

        let login = loginsForSection(indexPath.section)[indexPath.row]
        cell.style = .IconAndBothLabels
        cell.updateCellWithLogin(login)
        return cell
    }

    @objc func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        var firstHostnameCharacters = [Character]()
        data.forEach { login in
            let firstChar = login.hostname.uppercaseString[login.hostname.startIndex]
            if !firstHostnameCharacters.contains(firstChar) {
                firstHostnameCharacters.append(firstChar)
            }
        }
        return firstHostnameCharacters.map { String($0) }
    }

    @objc func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        guard let titles = sectionIndexTitlesForTableView(tableView) where index < titles.count && index >= 0 else {
            return 0
        }
        return titles.indexOf(title) ?? 0
    }

    @objc func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionIndexTitlesForTableView(tableView)?[section]
    }

    private func loginsForSection(section: Int) -> [LoginData] {
        guard let sectionTitles = sectionIndexTitlesForTableView(tableView) else {
            return []
        }
        let titleForSectionAtIndex = sectionTitles[section]
        return data.filter { $0.hostname.uppercaseString.startsWith(titleForSectionAtIndex) }
    }
}