/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import XCGLogger
import Storage

private let log = Logger.browserLogger

/// Displays the Top Sites panel in the HomeViewController
class TopSitesPanel: UIViewController {
    weak var homePanelDelegate: HomePanelDelegate?

    private let profile: Profile

    private lazy var collectionView: UICollectionView = {
        let collection = TopSitesCollectionView(frame: CGRectZero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIConstants.PanelBackgroundColor
        collection.delegate = self
        collection.dataSource = self.dataSource
        collection.registerClass(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.Identifier)
        collection.keyboardDismissMode = .OnDrag
        return collection
    }()

    private lazy var dataSource: TopSitesDataSource = {
        return TopSitesDataSource(
            profile: self.profile,
            data: Cursor(status: .Failure, msg: "Nothing loaded yet")
        )
    }()

    private lazy var layout: TopSitesLayout = {
        return TopSitesLayout()
    }()

    private lazy var maxFrecencyLimit: Int = {
        return 100
    }()

    private var editingThumbnails: Bool = false {
        didSet {
            if editingThumbnails != oldValue {
                dataSource.editingThumbnails = editingThumbnails

                if editingThumbnails {
                    homePanelDelegate?.homePanelWillEnterEditingMode?(self)
                }

                updateRemoveButtonStates()
            }
        }
    }

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELnotificationReceived:", name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELnotificationReceived:", name: NotificationPrivateDataClearedHistory, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
    }
}

// MARK: - View Controller Lifecycle
extension TopSitesPanel {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshHistory(maxFrecencyLimit)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Regular {
            layout.numberOfColumns = 3
            layout.spacing = 10
            layout.minimumVerticalSectionInset = 5
            layout.minimumHorizontalSectionInset = 5
        } else if traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Compact {
            layout.numberOfColumns = 5
            layout.spacing = 10
            layout.minimumVerticalSectionInset = 5
            layout.minimumHorizontalSectionInset = 5
        } else if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            layout.numberOfColumns = 5
            layout.spacing = 10
            layout.minimumVerticalSectionInset = 20
            layout.minimumHorizontalSectionInset = 20
        }

        layout.invalidateLayout()
    }
}

// MARK: - Selectors
extension TopSitesPanel {
    func SELnotificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
            refreshHistory(maxFrecencyLimit)
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }
}

// MARK: - Private Helpers
extension TopSitesPanel {
    private func updateDataSourceWithSites(result: Maybe<Cursor<Site>>) {
        if let data = result.successValue {
            dataSource.numberOfTilesToDisplay = min(layout.numberOfColumns * layout.numberOfRows, data.count)
            dataSource.data = data
            dataSource.profile = profile
            layout.invalidateLayout()
            collectionView.reloadData()
        }
    }

    private func updateRemoveButtonStates() {
        collectionView.visibleCells().forEach { cell in
            guard let thumbnailCell = cell as? ThumbnailCell else { return }
            guard let indexPath = self.collectionView.indexPathForCell(cell) else { return }
            if indexPath.row < dataSource.data.count {
                thumbnailCell.toggleRemoveButton(editingThumbnails)
            } else {
                thumbnailCell.toggleRemoveButton(false)
            }
        }
    }

    private func deleteHistoryTileForSite(site: Site, atIndexPath indexPath: NSIndexPath) {
        profile.history.removeSiteFromTopSites(site).uponQueue(dispatch_get_main_queue()) { _ in
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
                self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.dataSource.numberOfTilesToDisplay - 1, inSection: 0)])
            }, completion: nil)
        }
    }

    private func refreshHistory(frequencyLimit: Int) {
        self.profile.history.getSitesByFrecencyWithLimit(frequencyLimit).uponQueue(dispatch_get_main_queue(), block: { result in
            self.updateDataSourceWithSites(result)
        })
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TopSitesPanel: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if editingThumbnails {
            return
        }

        if let site = dataSource[indexPath.item] {
            // We're gonna call Top Sites bookmarks for now.
            let visitType = VisitType.Bookmark
            let destination = NSURL(string: site.url)?.domainURL() ?? NSURL(string: "about:blank")!
            homePanelDelegate?.homePanel(self, didSelectURL: destination, visitType: visitType)
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let thumbnailCell = cell as? ThumbnailCell {
            thumbnailCell.delegate = self

            if editingThumbnails && indexPath.item < dataSource.data.count && thumbnailCell.removeButton.hidden {
                thumbnailCell.removeButton.hidden = false
            }
        }
    }
}

// MARK: - HomePanel
extension TopSitesPanel: HomePanel {
    func endEditing() {
        editingThumbnails = false
    }
}

// MARK: - ThumbnailCellDelegate
extension TopSitesPanel: ThumbnailCellDelegate {
    func didRemoveThumbnail(thumbnailCell: ThumbnailCell) {
        if let indexPath = collectionView.indexPathForCell(thumbnailCell) {
            if let site = dataSource[indexPath.item] {
                self.deleteHistoryTileForSite(site, atIndexPath: indexPath)
            }
        }
    }

    func didLongPressThumbnail(thumbnailCell: ThumbnailCell) {
        editingThumbnails = true
    }
}

private class TopSitesCollectionView: UICollectionView {
    private override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Hide the keyboard if this view is touched.
        window?.rootViewController?.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
}
