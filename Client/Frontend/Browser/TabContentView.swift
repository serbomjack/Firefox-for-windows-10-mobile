/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

private class TabContentViewUX {
    static let TitleMargin = CGFloat(6)
    static let CloseButtonInset = CGFloat(10)

    // Scaling factor to make sure landscape iPhone screenshot fills view
    static let ImageScaleFactor = CGFloat(1.3)
}

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
            top: TabContentViewUX.CloseButtonInset,
            left: TabContentViewUX.CloseButtonInset,
            bottom: TabContentViewUX.CloseButtonInset,
            right: TabContentViewUX.CloseButtonInset)
        return closeButton
    }()

    lazy var urlBar: URLBarView = {
        let urlBar = URLBarView()
        urlBar.backgroundColor = UIColor.whiteColor()
        urlBar.setShowToolbar(self.shouldDisplayToolbar())
        return urlBar
    }()

    lazy var toolbar: BrowserToolbar = {
        return BrowserToolbar()
    }()

    private lazy var innerBorder: InnerStrokedView = {
        return InnerStrokedView()
    }()

    private var titleContainerFrame: CGRect {
        if self.expanded {
            return CGRect(origin: self.backgroundFrame.origin, size: CGSize(width: self.bounds.size.width, height: 0))
        } else {
            return CGRect(origin: self.backgroundFrame.origin, size: CGSize(width: self.bounds.size.width, height: TabTrayControllerUX.TextBoxHeight))
        }
    }

    private var backgroundFrame: CGRect {
        var backgroundFrame = CGRect()

        if self.expanded {
            var backgroundHeight = self.bounds.size.height - AppConstants.ToolbarHeight
            backgroundHeight -= self.shouldDisplayToolbar() ? AppConstants.ToolbarHeight : 0

            backgroundFrame.origin = CGPoint(x: 0, y: (AppConstants.ToolbarHeight + AppConstants.StatusBarHeight))
            backgroundFrame.size =
                CGSize(width: self.bounds.size.width, height: backgroundHeight)
        } else {
            backgroundFrame.size = CGSize(width: self.bounds.size.width * TabContentViewUX.ImageScaleFactor, height: self.bounds.size.height * TabContentViewUX.ImageScaleFactor)
            backgroundFrame.origin = CGPoint(x: 0, y: 0)
        }

        return backgroundFrame
    }

    var expanded: Bool = false {
        didSet {
            self.titleText.alpha = self.expanded ? 0 : 1
            self.closeButton.alpha = self.expanded ? 0 : 1
            self.favicon.alpha = self.expanded ? 0 : 1
            self.innerBorder.alpha = self.expanded ? 0 : 1

            // Update subview frames based on the expanded flag
            self.background.frame = self.backgroundFrame
            self.titleContainer.frame = self.titleContainerFrame
            self.setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.clipsToBounds = true
        self.opaque = true

        self.titleContainer.addSubview(self.closeButton)
        self.titleContainer.addSubview(self.titleText)
        self.titleContainer.addSubview(self.favicon)

        self.addSubview(self.urlBar)
        self.addSubview(self.toolbar)
        self.addSubview(self.background)
        self.addSubview(self.titleContainer)
        self.addSubview(self.innerBorder)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.innerBorder.frame = self.backgroundFrame

        var urlBarFrame = CGRect()
        urlBarFrame.origin = CGPointZero
        urlBarFrame.size = CGSize(width: self.bounds.size.width, height: AppConstants.ToolbarHeight + AppConstants.StatusBarHeight)
        self.urlBar.frame = urlBarFrame

        var toolbarFrame = CGRect()
        toolbarFrame.origin = CGPoint(x: 0, y: self.bounds.size.height - AppConstants.ToolbarHeight)
        toolbarFrame.size = CGSize(width: self.bounds.size.width, height: AppConstants.ToolbarHeight)
        self.toolbar.frame = toolbarFrame

        self.titleContainer.frame = self.titleContainerFrame

        var faviconFrame = CGRect()
        faviconFrame.size = CGSize(width: TabTrayControllerUX.FaviconSize, height: TabTrayControllerUX.FaviconSize)
        faviconFrame.center =
            CGPoint(x: TabContentViewUX.TitleMargin + (TabTrayControllerUX.FaviconSize / 2), y: self.titleContainer.frame.center.y)
        self.favicon.frame = faviconFrame

        var closeFrame = CGRect()
        closeFrame.size = CGSize(width: TabTrayControllerUX.TextBoxHeight, height: TabTrayControllerUX.TextBoxHeight)
        closeFrame.center =
            CGPoint(x: titleContainerFrame.size.width - TabContentViewUX.TitleMargin - (closeFrame.size.height / 2), y: CGRectGetMidY(titleContainerFrame))
        self.closeButton.frame = closeFrame

        var titleFrame = CGRect()
        titleFrame.size = CGSize(
                width: titleContainerFrame.size.width - (faviconFrame.size.width + TabContentViewUX.TitleMargin * 2 + closeFrame.size.width),
                height: TabTrayControllerUX.TextBoxHeight)
        titleFrame.center = CGPoint(x: titleContainerFrame.size.width / 2, y: titleContainerFrame.size.height / 2)
        self.titleText.frame = titleFrame

        self.background.frame = backgroundFrame
    }

    private func shouldDisplayToolbar() -> Bool {
        return self.traitCollection.verticalSizeClass == .Compact && self.traitCollection.horizontalSizeClass == .Regular
    }
}

// A transparent view with a rectangular border with rounded corners, stroked
// with a semi-transparent white border.
private class InnerStrokedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let strokeWidth = CGFloat(1)
        let halfWidth = strokeWidth / 2

        let path = UIBezierPath(roundedRect: CGRect(x: halfWidth,
            y: halfWidth,
            width: rect.width - strokeWidth,
            height: rect.height - strokeWidth),
            cornerRadius: TabTrayControllerUX.CornerRadius)
        
        path.lineWidth = strokeWidth
        UIColor.whiteColor().colorWithAlphaComponent(0.2).setStroke()
        path.stroke()
    }
}