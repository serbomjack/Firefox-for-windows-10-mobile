/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchView: UIView {
    private let searchTitleLabel: UILabel = {

    }()

    private let searchIcon: UIImageView = {
    }()

    private let closeButton: UIButton = {

    }()

    private let searchInputField: UITextField  = {

    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}