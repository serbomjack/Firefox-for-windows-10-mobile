/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

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
    static let NavButtonMargin = CGFloat(10)
}

private protocol TabCellDelegate: class {
    func tabCellDidClose(cell: TabCell)
    func cellHeightForCurrentDevice() -> CGFloat
}

private class TabCell: UICollectionViewCell {
    static let Identifier = "TabCellIdentifier"

    lazy var tabView: TabContentView = {
        return TabContentView()
    }()

    var animator: SwipeAnimator!
    weak var delegate: TabCellDelegate?

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
        self.animator.originalCenter = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMinY(self.frame))
    }

    @objc func SELdidPressClose() {
        delegate?.tabCellDidClose(self)
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

    private var settingsLeft: Constraint?
    private var addTabRight: Constraint?

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

        self.setupConstraints()
    }

    private func setupConstraints() {
        navBar.snp_makeConstraints { make in
            let topLayoutGuide = self.topLayoutGuide as! UIView
            make.top.equalTo(topLayoutGuide.snp_bottom)
            make.left.right.equalTo(self.view)
        }

        addTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.navBar)
            make.size.equalTo(self.navBar.snp_height)
            self.addTabRight = make.right.equalTo(self.navBar).offset(-TabTrayControllerUX.NavButtonMargin).constraint
        }

        settingsButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.navBar)
            make.size.equalTo(self.navBar.snp_height)
            self.settingsLeft = make.left.equalTo(self.navBar).offset(TabTrayControllerUX.NavButtonMargin).constraint
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

    private func tabViewFromBrowser(browser: Browser?, frame: CGRect) -> TabContentView {
        let tabView = TabContentView()
        tabView.background.image = browser?.screenshot
        tabView.titleText.text = browser?.displayTitle

        if let favIconUrlString = browser?.displayFavicon?.url {
            tabView.favicon.sd_setImageWithURL(NSURL(string: favIconUrlString))
        }

        // Show toolbar if we're on a smaller device, or else show it as part of the url bar
        if self.traitCollection.verticalSizeClass == .Compact || self.traitCollection.horizontalSizeClass == .Regular {
            tabView.urlBar.setShowToolbar(true)
        } else {
            tabView.urlBar.setShowToolbar(false)
        }

        tabView.frame = frame
        tabView.layoutIfNeeded()
        tabView.urlBar.updateConstraintsIfNeeded()
        return tabView
    }

    func transitionablePreShow(transitionable: Transitionable, options: TransitionOptions) {
        if let browserViewController = options.fromView as? BrowserViewController,
           let container = options.container,
           let browser = tabManager.selectedTab {

            let tabView = self.tabViewFromBrowser(browser, frame: browserViewController.view.frame)
            tabView.showExpanded()
            container.addSubview(tabView)

            // Layout tab tray view to let the collection view get it's frame
            self.view.layoutIfNeeded()
            tabView.layoutIfNeeded()

            options.moving = tabView
        }
    }

    func transitionablePreHide(transitionable: Transitionable, options: TransitionOptions) {
        let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: self.tabManager.selectedIndex, inSection: 0))
        if var cellRect = attributes?.frame, let browser = tabManager.selectedTab {
            cellRect = self.collectionView.convertRect(cellRect, toView: self.view)
            let selectedTabView = self.tabViewFromBrowser(browser, frame: cellRect)
            self.view.addSubview(selectedTabView)
            options.moving = selectedTabView
        }
    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        if let fakeTabView = options.moving as? TabContentView {
            addTabRight?.updateOffset(addTabButton.frame.size.width + TabTrayControllerUX.NavButtonMargin)
            settingsLeft?.updateOffset(-(settingsButton.frame.size.width + TabTrayControllerUX.NavButtonMargin))
            self.view.layoutIfNeeded()

            fakeTabView.frame = self.view.frame
            fakeTabView.layer.cornerRadius = 0
            fakeTabView.showExpanded()
            fakeTabView.layoutIfNeeded()
        }
    }

    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
        let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: self.tabManager.selectedIndex, inSection: 0))
        if var cellRect = attributes?.frame, let fakeTabView = options.moving as? TabContentView {
            addTabRight?.updateOffset(-TabTrayControllerUX.NavButtonMargin)
            settingsLeft?.updateOffset(TabTrayControllerUX.NavButtonMargin)
            self.view.layoutIfNeeded()

            cellRect = self.collectionView.convertRect(cellRect, toView: self.view)
            fakeTabView.frame = cellRect
            fakeTabView.layer.cornerRadius = TabTrayControllerUX.CornerRadius
            fakeTabView.showCollapsed()
            fakeTabView.layoutIfNeeded()
        }
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
        if let fakeTabView = options.moving as? TabContentView {
            fakeTabView.removeFromSuperview()
        }
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

extension TabTrayController: TabCellDelegate {
    private func tabCellDidClose(cell: TabCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        if let tab = tabManager[indexPath.item] {
            tabManager.removeTab(tab)
        }
    }
}
