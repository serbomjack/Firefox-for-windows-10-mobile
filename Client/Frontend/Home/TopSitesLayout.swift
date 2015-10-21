/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
*  A Basic POD struct that contains parameters for laying out items in Top Sites
*/
struct TopSitesLayoutParams {
    let numberOfColumns: Int
    let numberOfRows: Int
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let sectionInsets: UIEdgeInsets

    func itemSizeForCollectionViewSize(size: CGSize) -> CGSize {
        // Trim off the amount of whitespace we'll need in between the cells so we can simply divide the left
        // over space by the number of rows/columns to determine the size of each item
        let horizontalSpacingAmount = CGFloat(numberOfColumns - 1) * horizontalSpacing + sectionInsets.left + sectionInsets.right
        let verticalSpacingAmount = CGFloat(numberOfRows - 1) * verticalSpacing + sectionInsets.top + sectionInsets.bottom
        let leftOverSpace = CGSize(width: size.width - horizontalSpacingAmount, height: size.height - verticalSpacingAmount)
        let itemWidth = floor(leftOverSpace.width / CGFloat(numberOfColumns))
        let itemHeight = floor(leftOverSpace.height / CGFloat(numberOfRows))
        let minLength = min(itemHeight, itemWidth)
        return CGSize(width: minLength, height: minLength)
    }
}

private let IPhoneSmallLandscapeParams = TopSitesLayoutParams(
    numberOfColumns: 4,
    numberOfRows: 2,
    horizontalSpacing: 2,
    verticalSpacing: 2,
    sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
)

private let IPhoneSmallPortraitParams = TopSitesLayoutParams(
    numberOfColumns: 3,
    numberOfRows: 3,
    horizontalSpacing: 2,
    verticalSpacing: 2,
    sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
)

private let IPhonePortraitParams = TopSitesLayoutParams(
    numberOfColumns: 3,
    numberOfRows: 4,
    horizontalSpacing: 5,
    verticalSpacing: 5,
    sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
)

private let IPhoneLandscapeParams = TopSitesLayoutParams(
    numberOfColumns: 5,
    numberOfRows: 2,
    horizontalSpacing: 5,
    verticalSpacing: 5,
    sectionInsets: UIEdgeInsets(top: 5, left: 8, bottom: 8, right: 5)
)

private let IPadPortraitParams = TopSitesLayoutParams(
    numberOfColumns: 4,
    numberOfRows: 5,
    horizontalSpacing: 10,
    verticalSpacing: 10,
    sectionInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
)

private let IPadLandscapeParams = TopSitesLayoutParams(
    numberOfColumns: 5,
    numberOfRows: 3,
    horizontalSpacing: 10,
    verticalSpacing: 10,
    sectionInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
)

/**
*  A simple delegate that emits events for when the size classes have changed for the layout
*/
protocol TopSitesLayoutDelegate {
    func topSitesLayoutDidChangeSizeClass()
}

/// A UICollectionFlowLayout subclass that responds to traitCollection changes in order to
/// update it's current set of layout parameters for Top Sites
class TopSitesLayout: UICollectionViewLayout {

    var numberOfColumns: Int = 0

    var numberOfRows: Int = 0

    var spacing: CGFloat = 0

    var minEdgeSpacing: CGFloat = 0

    private var layoutRect: CGRect

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func collectionViewContentSize() -> CGSize {
        // We want Top Sites to never be scrollable so set the content size the same as our collection view size
        return collectionView?.bounds.size ?? CGSizeZero
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    }

    private func calculateLayoutRectForContentSize(size: CGSize, columns: Int, rows: Int) -> CGRect {
        let floatColumns = CGFloat(columns)
        let floatRows = CGFloat(rows)
        let scale = min(size.width / floatColumns, size.height / floatRows)
        return CGRect(origin: CGPointZero, size: CGSize(width: floatColumns * scale, height: floatRows * scale))
    }

    private func itemSizeForLayoutRect(rect: CGRect, spacing: CGFloat, columns: Int, rows: Int) -> CGSize {
        let floatColumns = CGFloat(columns)
        let floatRows = CGFloat(rows)
        let totalHorizontalSpacing = (floatColumns - 1) * spacing
        let totalVerticalSpacing = (floatRows - 1) * spacing
        let leftOverWidth = rect.width - totalHorizontalSpacing
        let leftOverHeight = rect.height - totalVerticalSpacing
        return CGSize(width: floor(leftOverWidth / floatColumns), height: floor(leftOverHeight / floatRows))
    }
}
