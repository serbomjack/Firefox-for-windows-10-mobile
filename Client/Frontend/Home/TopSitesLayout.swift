/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/// Layout that assigns positions to the tiles in the Top Sites panel. This layout does makes:
///     - Items have an aspect ratio of 1:1 (square)
///     - Spacing between each item vertically and horizontally are the same
///     - Group of items will be centered within the collection view
///     - No scrolling for the collection view. This is static grid.
class TopSitesLayout: UICollectionViewLayout {

    /// Number of items to place horizontally
    var numberOfColumns: Int = 1

    /// Number of items to place vertically. This is a computed property that is calculated by considering
    /// how large the content size is and the width of an item. The assumption is that each cell is a square
    /// so we can safely assume this.
    var numberOfRows: Int {
        let itemWidth = floor(collectionViewContentSize().width / CGFloat(numberOfColumns))
        return Int(collectionViewContentSize().height / itemWidth)
    }

    /// The amount of spacing between the items vertically and horizontally
    var spacing: CGFloat = 0

    /// The minimum amount of inset on the top/bottom of the layout rect.
    var minimumVerticalSectionInset: CGFloat = 0

    /// The minimum amount of inset on the left/bottom of the layout rect.
    var minimumHorizontalSectionInset: CGFloat = 0

    /// The layout rect is the area in which we will layout out items. This is calculated by considering the
    /// number of columns, inferring an item width, and calculating the height that will fit the most square 
    /// top site tiles we can fit in our container rect without going outside of it.
    private var layoutRect: CGRect = CGRectZero

    /// The CGRect that will fit our layout rect (the rect that will hold the items). When the section insets
    /// are zero, this is the same as a rect that is the size of the collection view with it's origin at zero.
    /// With section insets, it returns a CGRect that is insetted by those amounts origined at zero.
    private var containerRect: CGRect {
        let contentRect = CGRect(origin: CGPointZero, size: collectionViewContentSize())
        return CGRectInset(contentRect, minimumHorizontalSectionInset, minimumVerticalSectionInset)
    }

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareLayout() {
        super.prepareLayout()
        layoutRect = centerRectInContainer(calculateLayoutRectForContentSize())
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }

    override func collectionViewContentSize() -> CGSize {
        // We want Top Sites to never be scrollable so set the content size the same as our collection view size
        return collectionView?.bounds.size ?? CGSizeZero
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()

        guard let collectionView = collectionView else {
            return nil
        }

        // Confer with the data source to see what the least amount of items we need to show is
        let itemCount = min(numberOfColumns * numberOfRows, collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0) ?? 0)
        for i in 0..<itemCount {
            if let itemAttributes = layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) {
                attributes.append(itemAttributes)
            }
        }
        return attributes
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        let itemSize = itemSizeForLayoutRect(layoutRect)

        let column = CGFloat(indexPath.item % numberOfColumns)
        let row = CGFloat(indexPath.item / numberOfColumns)

        // Calculate the offset for the item based on column/row/spacing
        let origin = CGPoint(
            x: floor(layoutRect.origin.x + (itemSize.width * column) + (spacing * column)),
            y: floor(layoutRect.origin.y + (itemSize.height * row) + (spacing * row)))

        attributes.frame = CGRect(origin: origin, size: itemSize)
        return attributes
    }
}

// MARK: - Private Helpers
extension TopSitesLayout {

    /**
    Returns the layout rectangle that all of the items will be put into
    */
    private func calculateLayoutRectForContentSize() -> CGRect {
        let floatColumns = CGFloat(numberOfColumns)
        let floatRows = CGFloat(numberOfRows)
        let itemWidth = floor(containerRect.width / floatColumns)
        return CGRect(origin: CGPointZero, size: CGSize(width: floatColumns * itemWidth, height: floatRows * itemWidth))
    }

    /**
    Calculates item size from the given layout rect. This takes the spacing into account to return the correct size....

    - parameter rect: Rect to fit all of the items in

    - returns: CGSize for an item
    */
    private func itemSizeForLayoutRect(rect: CGRect) -> CGSize {
        let floatColumns = CGFloat(numberOfColumns)
        let floatRows = CGFloat(numberOfRows)
        let totalHorizontalSpacing = (floatColumns - 1) * spacing
        let totalVerticalSpacing = (floatRows - 1) * spacing
        let leftOverWidth = rect.width - totalHorizontalSpacing
        let leftOverHeight = rect.height - totalVerticalSpacing
        return CGSize(width: floor(leftOverWidth / floatColumns), height: floor(leftOverHeight / floatRows))
    }

    /**
    Updates the origin of the given rect to place it in the center of our container rect.

    - parameter rect: Rect to center in containerRect

    - returns: Updated rect origin that places it in the center of containerRect
    */
    private func centerRectInContainer(var rect: CGRect) -> CGRect {
        let x = (containerRect.width - rect.width) / 2 + containerRect.origin.x
        let y = (containerRect.height - rect.height) / 2 + containerRect.origin.y
        rect.origin = CGPoint(x: x, y: y)
        return rect
    }
}

