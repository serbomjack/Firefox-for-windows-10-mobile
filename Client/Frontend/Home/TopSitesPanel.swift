/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import XCGLogger
import Storage

private let log = Logger.browserLogger

extension UIView {
    public class func viewOrientationForSize(size: CGSize) -> UIInterfaceOrientation {
        return size.width > size.height ? UIInterfaceOrientation.LandscapeRight : UIInterfaceOrientation.Portrait
    }
}

/**
*  A small protocol that contains information about the number of columns/rows and cell sizes that are not
*  inferred from a data source. For example, when implemented by TopSitesPanel, these values are computed
*  using the size of the collection view.
*/
protocol TopSitesLayoutData {
    var numberOfColumns: Int { get }
    var numberOfRows: Int { get }
    var thumbnailWidth: CGFloat { get }
    var thumbnailHeight: CGFloat { get }
}

class TopSitesPanel: UIViewController {
    weak var homePanelDelegate: HomePanelDelegate?

    let profile: Profile

    private lazy var collectionView: UICollectionView = {
        let collection = TopSitesCollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
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
            data: Cursor(status: .Failure, msg: "Nothing loaded yet"),
            layoutData: self
        )
    }()

    var editingThumbnails: Bool = false {
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

    private let FrecencyQueryLimit = 24

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        refreshHistory(FrecencyQueryLimit)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.collectionView.collectionViewLayout.invalidateLayout()

        // Figure out with cells we need to remove/add to satisfy the new layout without reloading the collection view
        collectionView.performBatchUpdates({
            let previousCount = self.numberOfRows * self.numberOfColumns
            let indexPaths = [
                NSIndexPath(forRow: 10, inSection: 0),
                NSIndexPath(forRow: 11, inSection: 0)
            ]

            if previousCount == 10 {
                // Add 2
                self.collectionView.insertItemsAtIndexPaths(indexPaths)
            } else {
                // Remove 2
                self.collectionView.deleteItemsAtIndexPaths(indexPaths)
            }
        }, completion: nil)
    }
}

extension TopSitesPanel: TopSitesLayoutData {
    var numberOfColumns: Int {
        if UIView.viewOrientationForSize(self.view.bounds.size).isLandscape {
            return 5
        } else if UIScreen.mainScreen().traitCollection.horizontalSizeClass == .Compact {
            return 3
        } else {
            return 4
        }
    }

    var numberOfRows: Int {
        return Int((collectionView.bounds.height ?? self.thumbnailHeight) / self.thumbnailHeight)
    }

    var thumbnailWidth: CGFloat {
        return floor((collectionView.bounds.width - ThumbnailCellUX.Insets.left - ThumbnailCellUX.Insets.right) / CGFloat(numberOfColumns))
    }

    var thumbnailHeight: CGFloat {
        return thumbnailWidth / CGFloat(ThumbnailCellUX.ImageAspectRatio)
    }
}

// MARK: - Selectors
extension TopSitesPanel {
    func SELnotificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
            refreshHistory(FrecencyQueryLimit)
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
            self.dataSource.data = data
            self.dataSource.profile = self.profile

            // redraw now we've updated our sources
            self.collectionView.reloadData()
        }
    }

    private func updateRemoveButtonStates() {
//        for i in 0..<layout.thumbnailCount {
//            if let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as? ThumbnailCell {
//                //TODO: Only toggle the remove button for non-suggested tiles for now
//                if i < dataSource.data.count {
//                    cell.toggleRemoveButton(editingThumbnails)
//                } else {
//                    cell.toggleRemoveButton(false)
//                }
//            }
//        }
    }

    private func deleteHistoryTileForSite(site: Site, atIndexPath indexPath: NSIndexPath) {
        profile.history.removeSiteFromTopSites(site) >>== {
//            self.profile.history.getSitesByFrecencyWithLimit(self.layout.thumbnailCount).uponQueue(dispatch_get_main_queue(), block: { result in
//                self.updateDataSourceWithSites(result)
//                self.deleteOrUpdateSites(result, indexPath: indexPath)
//            })
        }
    }

    private func refreshHistory(frequencyLimit: Int) {
        self.profile.history.getSitesByFrecencyWithLimit(frequencyLimit).uponQueue(dispatch_get_main_queue(), block: { result in
            self.updateDataSourceWithSites(result)
        })
    }

    private func deleteOrUpdateSites(result: Maybe<Cursor<Site>>, indexPath: NSIndexPath) {
//        if let data = result.successValue {
//            let numOfThumbnails = self.layout.thumbnailCount
//            collectionView.performBatchUpdates({
                // If we have enough data to fill the tiles after the deletion, then delete and insert the next one from data
//                if (data.count + SuggestedSites.count >= numOfThumbnails) {
//                    self.collectionView.deleteItemsAtIndexPaths([indexPath])
//                    self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: numOfThumbnails - 1, inSection: 0)])
//                }

                // If we don't have enough to fill the thumbnail tile area even with suggested tiles, just delete
//                else if (data.count + SuggestedSites.count) < numOfThumbnails {
//                    self.collectionView.deleteItemsAtIndexPaths([indexPath])
//                }
//            }, completion: { _ in
//                self.updateRemoveButtonStates()
//            })
//        }
    }
}

extension TopSitesPanel: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: thumbnailWidth, height: thumbnailHeight)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }

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

extension TopSitesPanel: HomePanel {
    func endEditing() {
        editingThumbnails = false
    }
}

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
