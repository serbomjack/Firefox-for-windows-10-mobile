/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

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

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.whiteColor()
        self.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.clipsToBounds = true
        self.opaque = true

        self.titleContainer.addSubview(self.closeButton)
        self.titleContainer.addSubview(self.titleText)
        self.titleContainer.addSubview(self.favicon)

        self.addSubview(self.background)
        self.addSubview(self.titleContainer)

        self.setNeedsUpdateConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        self.background.snp_remakeConstraints { make in
            make.bottom.top.left.right.equalTo(self)
        }

        self.titleContainer.snp_remakeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(TabTrayControllerUX.TextBoxHeight)
        }

        self.favicon.snp_remakeConstraints { make in
            make.left.equalTo(TitleMargin)
            make.centerY.equalTo(self.titleContainer)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
        }

        self.titleText.snp_remakeConstraints { make in
            make.centerY.equalTo(self.titleContainer)
            make.left.equalTo(self.favicon.snp_right).offset(TitleMargin)
            make.right.equalTo(self.closeButton.snp_left).offset(TitleMargin)
            make.height.equalTo(self)
        }

        self.closeButton.snp_remakeConstraints { make in
            make.right.equalTo(self.titleContainer)
            make.centerY.equalTo(self.titleContainer)
            make.size.equalTo(self.titleContainer.snp_height)
        }
    }
}