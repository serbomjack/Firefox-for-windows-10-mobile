/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let CellBackgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
    static let BackgroundColor = AppConstants.BackgroundColor
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(18.0)
    static let Margin = CGFloat(15)
    static let ToolbarBarTintColor = AppConstants.BackgroundColor
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let TabTitleTextColor = UIColor.blackColor()
    static let TabTitleTextFont = AppConstants.DefaultSmallFontBold
    static let CloseButtonSize = CGFloat(18.0)
    static let CloseButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(10)
    static let NumberOfColumnsCompact = 1
    static let NumberOfColumnsRegular = 3
}

private protocol CustomCellDelegate: class {
    func customCellDidClose(cell: TabCell)
    func cellHeightForCurrentDevice() -> CGFloat
}

private class TabCell: UICollectionViewCell {
    static let Identifier = "TabCellIdentifier"

    lazy var tabView: TabContentView = {
        return TabContentView()
    }()

    var tab: Browser? {
        didSet {
            self.tabView.titleText.text = tab?.title
            if let favIcon = tab?.displayFavicon {
                self.tabView.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
            }
        }
    }

    var animator: SwipeAnimator!
    weak var delegate: CustomCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.tabView)
        self.animator = SwipeAnimator(animatingView: self.tabView, containerView: self)
        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: "SELcloseWithoutGesture")
        ]
        
        self.setNeedsUpdateConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private override func updateConstraints() {
        super.updateConstraints()
        self.tabView.snp_remakeConstraints { make in
            make.top.bottom.left.right.equalTo(self.contentView)
        }
    }

    private override func layoutSubviews() {
        super.layoutSubviews()
        self.animator.originalCenter = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
    }

    private override func prepareForReuse() {
        // Reset any close animations.
        self.tabView.transform = CGAffineTransformIdentity
        self.tabView.alpha = 1
    }

    @objc func SELdidPressClose() {
        delegate?.customCellDidClose(self)
    }
}

class TabTrayController: UIViewController, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var tabManager: TabManager!
    var profile: Profile!
    var numberOfColumns: Int!

    lazy var navBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.barTintColor = TabTrayControllerUX.ToolbarBarTintColor
        navBar.tintColor = UIColor.whiteColor()
        navBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navBar.translucent = false
        return navBar
    }()

    lazy var addTabButton: UIButton = {
        let addTabButton = UIButton()
        addTabButton.setImage(UIImage(named: "add"), forState: .Normal)
        addTabButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: .TouchUpInside)
        addTabButton.accessibilityLabel = NSLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
        return addTabButton
    }()

    lazy var settingsButton: UIButton = {
        let settingsButton = UIButton()
        settingsButton.setImage(UIImage(named: "settings"), forState: .Normal)
        settingsButton.addTarget(self, action: "SELdidClickSettingsItem", forControlEvents: .TouchUpInside)
        settingsButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button in the Tab Tray.")
        return settingsButton
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(TabCell.self, forCellWithReuseIdentifier: TabCell.Identifier)
        collectionView.backgroundColor = TabTrayControllerUX.BackgroundColor
        return collectionView
    }()

    // MARK: View Controller Overrides and Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
        tabManager.addDelegate(self)

        numberOfColumns = numberOfColumnsForCurrentSize()

        self.view.addSubview(collectionView)
        self.view.addSubview(navBar)
        self.view.addSubview(addTabButton)
        self.view.addSubview(settingsButton)

        self.updateViewConstraints()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        navBar.snp_remakeConstraints { make in
            let topLayoutGuide = self.topLayoutGuide as! UIView
            make.top.equalTo(topLayoutGuide.snp_bottom)
            make.left.right.equalTo(self.view)
        }

        addTabButton.snp_remakeConstraints { make in
            make.centerY.equalTo(self.navBar)
            make.size.equalTo(self.navBar.snp_height)
            make.rightMargin.equalTo(10)
        }

        settingsButton.snp_remakeConstraints { make in
            make.centerY.equalTo(self.navBar)
            make.size.equalTo(self.navBar.snp_height)
            make.leftMargin.equalTo(10)
        }

        collectionView.snp_makeConstraints { make in
            make.top.equalTo(navBar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        numberOfColumns = numberOfColumnsForCurrentSize()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    private func numberOfColumnsForCurrentSize() -> Int {
        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact {
            return TabTrayControllerUX.NumberOfColumnsRegular
        } else if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            return TabTrayControllerUX.NumberOfColumnsCompact
        } else {
            return TabTrayControllerUX.NumberOfColumnsRegular
        }
    }

    func cellHeightForCurrentDevice() -> CGFloat {
        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact {
            return TabTrayControllerUX.TextBoxHeight * 5
        } else if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            return TabTrayControllerUX.TextBoxHeight * 5
        } else {
            return TabTrayControllerUX.TextBoxHeight * 8
        }
    }

    // MARK: Selectors
    func SELdidClickDone() {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func SELdidClickSettingsItem() {
        let controller = SettingsNavigationController()
        controller.profile = profile
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func SELdidClickAddTab() {
        tabManager?.addTab()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Collection View Delegate/Data Source
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager[indexPath.item]
        tabManager.selectTab(tab)
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TabCell.Identifier, forIndexPath: indexPath) as! TabCell
        cell.animator.delegate = self
        cell.delegate = self

        if let tab = tabManager[indexPath.item] {
            cell.tabView.titleText.text = tab.displayTitle
            cell.accessibilityLabel = tab.displayTitle
            cell.isAccessibilityElement = true

            if let favIconURLString = tab.displayFavicon?.url {
                cell.tabView.favicon.sd_setImageWithURL(NSURL(string: favIconURLString))
            } else {
                cell.tabView.favicon.image = UIImage(named: "defaultFavicon")
            }
            cell.tabView.background.image = tab.screenshot
        }

        cell.tabView.closeButton.addTarget(cell,
            action: "SELdidPressClose", forControlEvents: UIControlEvents.TouchUpInside)
        return cell
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabManager.count
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let cellWidth = (collectionView.bounds.width - TabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns)
        return CGSizeMake(cellWidth, self.cellHeightForCurrentDevice())
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }
}

extension TabTrayController: Transitionable {

//    private func getTransitionCell(options: TransitionOptions, browser: Browser?) -> TabCell {
//        var transitionCell: TabCell
//        if let cell = options.moving as? TabCell {
//            transitionCell = cell
//        } else {
//            transitionCell = CustomCell(frame: options.container!.frame)
//            options.moving = transitionCell
//        }
//
//        transitionCell.background.image = browser?.screenshot
//        transitionCell.titleText.text = browser?.displayTitle
//
//        if let favIcon = browser?.displayFavicon {
//            transitionCell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
//        }
//        return transitionCell
//    }

    func transitionablePreShow(transitionable: Transitionable, options: TransitionOptions) {
    }

    func transitionablePreHide(transitionable: Transitionable, options: TransitionOptions) {
        let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: self.tabManager.selectedIndex, inSection: 0))
        if var cellRect = attributes?.frame {
            cellRect = self.collectionView.convertRect(cellRect, toView: self.view)
            let selectedTabView = TabContentView()
            selectedTabView.frame = cellRect
            self.view.addSubview(selectedTabView)
            options.moving = selectedTabView
        }
    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        if let fakeTabView = options.moving as? TabContentView {
            fakeTabView.frame = self.view.frame
            fakeTabView.layer.cornerRadius = 0
            fakeTabView.expanded = true
            fakeTabView.layoutIfNeeded()
        }

        // Create a fake cell that is shown fullscreen
//        if let container = options.container {
//            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
//            var hasToolbar = false
//            if let fromView = options.fromView as? BrowserViewController {
//                hasToolbar = fromView.shouldShowToolbarForTraitCollection(self.traitCollection)
//            } else if let toView = options.toView as? BrowserViewController {
//                hasToolbar = toView.shouldShowToolbarForTraitCollection(self.traitCollection)
//            }
//
//            cell.showFullscreen(container, table: collectionView, shouldOffset: hasToolbar)
//            cell.layoutIfNeeded()
//            options.cellFrame = cell.frame
//
//            cell.title.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -cell.title.frame.height)
//
//        }
//
//        collectionViewTransitionSnapshot?.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)
//        collectionViewTransitionSnapshot?.alpha = 0
//
//        let buttonOffset = addTabButton.frame.width + TabTrayControllerUX.ToolbarButtonOffset
//        addTabButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, buttonOffset , 0)
//        settingsButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -buttonOffset , 0)
    }

    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
//        if let container = options.container {
//            // Create a fake cell that is at the selected index
//            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
//            cell.showAt(tabManager.selectedIndex, container: container, table: collectionView)
//            cell.layoutIfNeeded()
//            options.cellFrame = cell.frame
//        }
//
//
//        collectionViewTransitionSnapshot?.transform = CGAffineTransformIdentity
//        collectionViewTransitionSnapshot?.alpha = 1
//
//        addTabButton.transform = CGAffineTransformIdentity
//        settingsButton.transform = CGAffineTransformIdentity
//        navBar.alpha = 1
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
//        if let cell = options.moving as? CustomCell {
//            cell.removeFromSuperview()
//
////            cell.innerStroke.alpha = 0
////            cell.innerStroke.hidden = false
////
//            collectionViewTransitionSnapshot?.removeFromSuperview()
//            collectionView.hidden = false
//
//            navBar.hidden = false
//            collectionView.backgroundColor = TabTrayControllerUX.BackgroundColor
//            if let tab = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0)) as? CustomCell {
//                UIView.animateWithDuration(0.55, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { _ in
//                    cell.innerStroke.alpha = 1
//
//                    }, completion: { _ in
//                        return
//                })
//            }
//        }
    }
}

extension TabTrayController: SwipeAnimatorDelegate {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView) {
        let tabCell = animator.container as! TabCell
        if let indexPath = self.collectionView.indexPathForCell(tabCell) {
            if let tab = tabManager[indexPath.item] {
                tabManager.removeTab(tab)
            }
        }
    }
}

extension TabTrayController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?) {
        // Our UI doesn't care about what's selected
    }

    func tabManager(tabManager: TabManager, didCreateTab tab: Browser) {
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser, atIndex index: Int) {
        self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser, atIndex index: Int) {
        self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }
}

extension TabTrayController: CustomCellDelegate {
    private func customCellDidClose(cell: TabCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        if let tab = tabManager[indexPath.item] {
            tabManager.removeTab(tab)
        }
    }
}

// A transparent view with a rectangular border with rounded corners, stroked
// with a semi-transparent white border.
//private class InnerStrokedView: UIView {
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.backgroundColor = UIColor.clearColor()
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func drawRect(rect: CGRect) {
//        let strokeWidth = 1.0 as CGFloat
//        let halfWidth = strokeWidth/2 as CGFloat
//
//        let path = UIBezierPath(roundedRect: CGRect(x: halfWidth,
//            y: halfWidth,
//            width: rect.width - strokeWidth,
//            height: rect.height - strokeWidth),
//            cornerRadius: TabTrayControllerUX.CornerRadius)
//        
//        path.lineWidth = strokeWidth
//        UIColor.whiteColor().colorWithAlphaComponent(0.2).setStroke()
//        path.stroke()
//    }
//}
