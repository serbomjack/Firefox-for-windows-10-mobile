/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import XCGLogger
import Storage

/// Data source that provides the Top Sites panel with it's data
class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var data: Cursor<Site>
    var profile: Profile
    var editingThumbnails: Bool = false

    private(set) internal var numberOfTilesToDisplay: Int = 0

    init(profile: Profile, data: Cursor<Site>) {
        self.data = data
        self.profile = profile
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Cells for the top site thumbnails.
        let site = self[indexPath.item]!
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailCell.Identifier, forIndexPath: indexPath) as! ThumbnailCell

        if indexPath.item >= data.count {
            return configureTileForSuggestedSite(cell, site: site as! SuggestedSite)
        }
        return configureTileForSite(cell, site: site)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Unlike your typical data source pattern, the number of tiles to display is not only inferred from 
        // the data set but also the layout since we want to show a fixed amount of tiles depending on the
        // device/orientation. See TopSitesPanel.updateTopSiteTilesForSize().
        return numberOfTilesToDisplay
    }

    func updateNumberOfTilesToDisplay(numOfTiles: Int) {
        numberOfTilesToDisplay = numOfTiles
    }
}

// MARK: - Private Helpers
extension TopSitesDataSource {
    private func setDefaultThumbnailBackground(cell: ThumbnailCell) {
        cell.imageView.image = UIImage(named: "defaultTopSiteIcon")!
        cell.imageView.contentMode = UIViewContentMode.Center
    }

    private func getFavicon(cell: ThumbnailCell, site: Site) {
        self.setDefaultThumbnailBackground(cell)

        if let url = site.url.asURL {
            FaviconFetcher.getForURL(url, profile: profile) >>== { icons in
                if (icons.count > 0) {
                    cell.imageView.sd_setImageWithURL(icons[0].url.asURL!) { (img, err, type, url) -> Void in
                        if let img = img {
                            cell.blurAndSetAsBackground(img)
                            cell.image = img
                        } else {
                            let icon = Favicon(url: "", date: NSDate(), type: IconType.NoneFound)
                            self.profile.favicons.addFavicon(icon, forSite: site)
                            self.setDefaultThumbnailBackground(cell)
                        }
                    }
                }
            }
        }
    }

    private func configureTileForSite(cell: ThumbnailCell, site: Site) -> ThumbnailCell {

        // We always want to show the domain URL, not the title.
        //
        // Eventually we can do something more sophisticated — e.g., if the site only consists of one
        // history item, show it, and otherwise use the longest common sub-URL (and take its title
        // if you visited that exact URL), etc. etc. — but not yet.
        //
        // The obvious solution here and in collectionView:didSelectItemAtIndexPath: is for the cursor
        // to return domain sites, not history sites -- that is, with the right icon, title, and URL --
        // and for this code to just use what it gets.
        //
        // Instead we'll painstakingly re-extract those things here.

        let domainURL = NSURL(string: site.url)?.normalizedHost() ?? site.url
        cell.textLabel.text = domainURL
        cell.imageWrapper.backgroundColor = UIColor.clearColor()

        // Resets used cell's background image so that it doesn't get recycled when a tile doesn't update its background image.
        cell.clearBackgroundImg()
        cell.accessibilityLabel = cell.textLabel.text
        cell.removeButton.hidden = !editingThumbnails

        if let icon = site.icon {
            // We've looked before recently and didn't find a favicon
            switch icon.type {
            case .NoneFound where NSDate().timeIntervalSinceDate(icon.date) < FaviconFetcher.ExpirationTime:
                self.setDefaultThumbnailBackground(cell)
            default:
                cell.imageView.sd_setImageWithURL(icon.url.asURL, completed: { (img, err, type, url) -> Void in
                    if let img = img {
                        cell.blurAndSetAsBackground(img)
                        cell.image = img
                    } else {
                        self.getFavicon(cell, site: site)
                    }
                })
            }
        } else {
            getFavicon(cell, site: site)
        }

        return cell
    }

    private func configureTileForSuggestedSite(cell: ThumbnailCell, site: SuggestedSite) -> ThumbnailCell {
        cell.textLabel.text = site.title.isEmpty ? NSURL(string: site.url)?.normalizedHostAndPath() : site.title
        cell.imageWrapper.backgroundColor = site.backgroundColor
        cell.clearBackgroundImg()
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        cell.accessibilityLabel = cell.textLabel.text
        cell.removeButton.hidden = true

        if let icon = site.wordmark.url.asURL,
           let host = icon.host {
            if icon.scheme == "asset" {
                cell.imageView.image = UIImage(named: host)
            } else {
                cell.imageView.sd_setImageWithURL(icon, completed: { img, err, type, key in
                    if img == nil {
                        self.setDefaultThumbnailBackground(cell)
                    }
                })
            }
        } else {
            self.setDefaultThumbnailBackground(cell)
        }

        return cell
    }

    subscript(index: Int) -> Site? {
        if data.status != .Success {
            return nil
        }

        if index >= data.count {
            return SuggestedSites[index - data.count]
        }
        return data[index] as Site?
    }
}
