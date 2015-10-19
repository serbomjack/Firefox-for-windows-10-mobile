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

/// A UICollectionFlowLayout subclass that responds to traitCollection changes in order to
/// update it's current set of layout parameters for Top Sites
class TopSitesLayout: UICollectionViewFlowLayout {
    private let portraitParams = TopSitesLayoutParams(
        numberOfColumns: 3,
        numberOfRows: 4,
        horizontalSpacing: 10,
        verticalSpacing: 10,
        sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    )

    private let landscapeParams = TopSitesLayoutParams(
        numberOfColumns: 5,
        numberOfRows: 2,
        horizontalSpacing: 10,
        verticalSpacing: 10,
        sectionInsets: UIEdgeInsets(top: 5, left: 8, bottom: 8, right: 5)
    )

    private let ipadParams = TopSitesLayoutParams(
        numberOfColumns: 5,
        numberOfRows: 6,
        horizontalSpacing: 10,
        verticalSpacing: 10,
        sectionInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    )

    private(set) var currentParams: TopSitesLayoutParams?

    var numberOfColumns: Int {
        return currentParams?.numberOfColumns ?? 0
    }

    var numberOfRows: Int {
        return currentParams?.numberOfRows ?? 0
    }

    func reflowLayoutForTraitCollection(traitCollection: UITraitCollection) {
        guard let size = collectionView?.frame.size where !CGSizeEqualToSize(size, CGSizeZero) else {
            return
        }

        // iPhone 4S/5/5s/6/6 plus landscape
        if (traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Compact) ||
            (traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Compact) {
            currentParams = landscapeParams
        }

        // iPhone 4S/5/5s/6/6 plus portrait
        else if (traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Regular) {
            currentParams = portraitParams
        }

        // All iPads portrait and landscape
        else if (traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular) {
            currentParams = ipadParams
        } else {
            currentParams = portraitParams
        }
    }
}
