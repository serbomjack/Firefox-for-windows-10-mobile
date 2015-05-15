/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

let TitleMargin = CGFloat(6)
let CloseButtonInset = CGFloat(10)

/**
*  Used to display the content within a Tab cell that's shown in the TabTrayController
*/
class TabContentView: UIView {

    lazy var background: UIImageViewAligned = {
        let browserImageView = UIImageViewAligned()
        browserImageView.contentMode = UIViewContentMode.ScaleAspectFill
        browserImageView.clipsToBounds = true
        browserImageView.alignLeft = true
        browserImageView.alignTop = true
        browserImageView.backgroundColor = UIColor.whiteColor()
        return browserImageView
    }()

    lazy var titleText: UILabel = {
        let titleText = UILabel()
        titleText.textColor = TabTrayControllerUX.TabTitleTextColor
        titleText.backgroundColor = UIColor.clearColor()
        titleText.textAlignment = NSTextAlignment.Left
        titleText.userInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.font = TabTrayControllerUX.TabTitleTextFont
        return titleText
    }()

    lazy var titleContainer: UIVisualEffectView = {
        let title = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        title.layer.shadowColor = UIColor.blackColor().CGColor
        title.layer.shadowOpacity = 0.2
        title.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        title.layer.shadowRadius = 0
        title.clipsToBounds = true
        return title
    }()

    lazy var favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.backgroundColor = UIColor.clearColor()
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        return favicon
    }()

    lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
        closeButton.imageEdgeInsets = UIEdgeInsets(
            top: CloseButtonInset,
            left: CloseButtonInset,
            bottom: CloseButtonInset,
            right: CloseButtonInset)
        return closeButton
    }()

    lazy var urlBar: URLBarView = {
        let urlBar = URLBarView()
        urlBar.setTranslatesAutoresizingMaskIntoConstraints(false)
        return urlBar
    }()

    private var titleContainerHeight: Constraint?
    private var backgroundTop: Constraint?

    var expanded: Bool = false {
        didSet {
            self.titleContainerHeight?.updateOffset(self.expanded ? 0 : TabTrayControllerUX.TextBoxHeight)
            self.backgroundTop?.updateOffset(self.expanded ? AppConstants.ToolbarHeight + AppConstants.StatusBarHeight : 0)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.whiteColor()
        self.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.clipsToBounds = true
        self.opaque = true

        self.titleContainer.addSubview(self.closeButton)
        self.titleContainer.addSubview(self.titleText)
        self.titleContainer.addSubview(self.favicon)

        self.addSubview(self.urlBar)
        self.addSubview(self.background)
        self.addSubview(self.titleContainer)

        self.setupConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        self.background.snp_makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            self.backgroundTop = make.top.equalTo(self).constraint
        }

        self.urlBar.snp_makeConstraints { make in
            make.left.right.top.equalTo(self)

            //TODO: URLBarView needs to be updated without status bar height included
            make.height.equalTo(AppConstants.ToolbarHeight + AppConstants.StatusBarHeight)
        }

        self.titleContainer.snp_makeConstraints { make in
            make.left.right.top.equalTo(background)
            self.titleContainerHeight = make.height.equalTo(TabTrayControllerUX.TextBoxHeight).constraint
        }

        self.favicon.snp_makeConstraints { make in
            make.left.equalTo(TitleMargin)
            make.centerY.equalTo(self.titleContainer)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
        }

        self.titleText.snp_makeConstraints { make in
            make.centerY.equalTo(self.titleContainer)
            make.left.equalTo(self.favicon.snp_right).offset(TitleMargin)
            make.right.equalTo(self.closeButton.snp_left).offset(TitleMargin)
            make.height.equalTo(self)
        }

        self.closeButton.snp_makeConstraints { make in
            make.right.equalTo(self.titleContainer)
            make.centerY.equalTo(self.titleContainer)
            make.size.equalTo(self.titleContainer.snp_height)
        }
    }
}