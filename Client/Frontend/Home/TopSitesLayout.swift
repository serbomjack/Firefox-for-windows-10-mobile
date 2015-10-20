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
class TopSitesLayout: UICollectionViewFlowLayout {

    private(set) var layoutParams: TopSitesLayoutParams?

    private var horizontalSize: FXSizeClass = .SizeUndefined

    private var verticalSize: FXSizeClass = .SizeUndefined

    var topSitesDelegate: TopSitesLayoutDelegate?

    var numberOfColumns: Int {
        return layoutParams?.numberOfColumns ?? 0
    }

    var numberOfRows: Int {
        return layoutParams?.numberOfRows ?? 0
    }

    func setHorizontalSize(horizontalSize: FXSizeClass, andVerticalSize verticalSize: FXSizeClass) {
        // Don't do anything if nothing has changed
        if horizontalSize == self.horizontalSize && verticalSize == self.verticalSize {
            return
        }

        switch (horizontalSize, verticalSize) {

        // Portrait small iPhone
        case let (h, v) where h == .Size320 && v == .Size480:
            layoutParams = IPhoneSmallPortraitParams

        // Portrait tall iPhone
        case let (h, v) where h == .Size320 && v == .Size568:
            layoutParams = IPhonePortraitParams
        case let (h, v) where h == .Size375 && v == .Size667:
            layoutParams = IPhonePortraitParams
        case let (h, v) where h == .Size414 && v == .Size736:
            layoutParams = IPhonePortraitParams

        // Landscape small iPhone
        case let (h, v) where h == .Size480 && v == .Size320:
            layoutParams = IPhoneSmallLandscapeParams

        // Landscape tall iPhone
        case let (h, v) where h == .Size568 && v == .Size320:
            layoutParams = IPhoneLandscapeParams
        case let (h, v) where h == .Size667 && v == .Size375:
            layoutParams = IPhoneLandscapeParams
        case let (h, v) where h == .Size736 && v == .Size414:
            layoutParams = IPhoneLandscapeParams

        // Landscape iPad
        case let (h, v) where h == .Size1024 && v == .Size768:
            layoutParams = IPadLandscapeParams

        // Portrait iPad
        case let (h, v) where h == .Size768 && v == .Size1024:
            layoutParams = IPadPortraitParams

        default:
            break
        }

        topSitesDelegate?.topSitesLayoutDidChangeSizeClass()
    }
}
