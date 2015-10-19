/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/// A custom UICollectionViewLayout for Top Site items. A unique characteristic of this layout is that 
/// when rotated, the cells do not change alpha but flow into the correct place. The layout also calculates
/// the frame of each cell by factoring in the number of columns/rows available. Based on a fixed number of
/// columns for a given device orientation/size, the height of the cells are calculated based on a specific
/// aspect ratio and insets to allow the cells to fit snug in the collection view.
class TopSitesLayout: UICollectionViewLayout {
    var aspectRatio: CGFloat = 1.0

    var numberOfColumns: Int { return columnsForSize(collectionViewContentSize()) }

    var itemWidth: CGFloat { return itemWidthForSize(collectionViewContentSize()) }

    var itemHeight: CGFloat { return itemHeightForSize(collectionViewContentSize()) }

    var numberOfRows: Int { return rowsForSize(collectionViewContentSize()) }

    private var layoutAttributes:[UICollectionViewLayoutAttributes]?

    override func prepareLayout() {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for section in 0..<(self.collectionView?.numberOfSections() ?? 0) {
            for item in 0..<(self.collectionView?.numberOfItemsInSection(section) ?? 0) {
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                guard let attrs = self.layoutAttributesForItemAtIndexPath(indexPath) else { continue }
                layoutAttributes.append(attrs)
            }
        }
        self.layoutAttributes = layoutAttributes
    }

    override func collectionViewContentSize() -> CGSize {
        let size = collectionView?.bounds.size ?? CGSizeZero
        return size
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attrs = [UICollectionViewLayoutAttributes]()
        if let layoutAttributes = self.layoutAttributes {
            for attr in layoutAttributes {
                if CGRectIntersectsRect(rect, attr.frame) {
                    attrs.append(attr)
                }
            }
        }
        return attrs
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        let oldBounds = self.collectionView?.bounds ?? CGRectZero
        if !CGSizeEqualToSize(oldBounds.size, newBounds.size) {
            return true
        }
        return false
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        let row = floor(Double(indexPath.item / numberOfColumns))
        let col = indexPath.item % numberOfColumns
        let insets = ThumbnailCellUX.Insets
        let x = insets.left + itemWidth * CGFloat(col)
        let y = insets.top + CGFloat(row) * itemHeight
        attr.frame = CGRectMake(ceil(x), ceil(y), itemWidth, itemHeight)
        return attr
    }

    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = layoutAttributesForItemAtIndexPath(itemIndexPath)
        attributes?.alpha = 1
        return attributes
    }

    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = layoutAttributesForItemAtIndexPath(itemIndexPath)
        attributes?.alpha = 0
        return attributes
    }
}

extension TopSitesLayout {
    func numberOfSlotsAvailableForSize(size: CGSize) -> Int {
        return columnsForSize(size) * rowsForSize(size)
    }

    /**
    Calculates an approximation of the number of tiles we want to display for the given orientation. This
    method uses the screen's size as it's basis for the calculation instead of the collectionView's since the
    collectionView's bounds is determined until the next layout pass.
    - parameter orientation: Orientation to calculate number of tiles for
    - returns: Rough tile count we will be displaying for the passed in orientation
    */
    func calculateApproxThumbnailCountForOrientation(orientation: UIInterfaceOrientation) -> Int {
        let size = UIScreen.mainScreen().bounds.size
        let portraitSize = CGSize(width: min(size.width, size.height), height: max(size.width, size.height))

        func calculateRowsForSize(size: CGSize, columns: Int) -> Int {
            let insets = ThumbnailCellUX.Insets
            let thumbnailWidth = (size.width - insets.left - insets.right) / CGFloat(columns)
            let thumbnailHeight = thumbnailWidth / CGFloat(ThumbnailCellUX.ImageAspectRatio)
            return max(2, Int(size.height / thumbnailHeight))
        }

        let numberOfColumns: Int
        let numberOfRows: Int

        if UIInterfaceOrientationIsLandscape(orientation) {
            numberOfColumns = 5
            numberOfRows = calculateRowsForSize(CGSize(width: portraitSize.height, height: portraitSize.width), columns: numberOfColumns)
        } else {
            numberOfColumns = 4
            numberOfRows = calculateRowsForSize(portraitSize, columns: numberOfColumns)
        }

        return numberOfColumns * numberOfRows
    }

    private func columnsForSize(size: CGSize) -> Int {
        if viewOrientationForSize(size).isLandscape {
            return 5
        } else if UIScreen.mainScreen().traitCollection.horizontalSizeClass == .Compact {
            return 3
        } else {
            return 4
        }
    }

    private func rowsForSize(size: CGSize) -> Int {
        return Int((size.height ?? itemHeightForSize(size)) / itemHeightForSize(size))
    }

    private func itemWidthForSize(size: CGSize) -> CGFloat {
        return floor((size.width - ThumbnailCellUX.Insets.left - ThumbnailCellUX.Insets.right) / CGFloat(columnsForSize(size)))
    }

    private func itemHeightForSize(size: CGSize) -> CGFloat {
        return floor(itemWidthForSize(size) / aspectRatio)
    }

    private func viewOrientationForSize(size: CGSize) -> UIInterfaceOrientation {
        return size.width > size.height ? UIInterfaceOrientation.LandscapeRight : UIInterfaceOrientation.Portrait
    }
}
