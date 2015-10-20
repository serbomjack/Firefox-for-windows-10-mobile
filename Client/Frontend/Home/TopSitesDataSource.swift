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

    var numberOfTilesToDisplay: Int = 0

    init(profile: Profile, data: Cursor<Site>) {
        self.data = data
        self.profile = profile
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Cells for the top site thumbnails.
        let site = self[indexPath.item]!
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailCell.Identifier, forIndexPath: indexPath) as! ThumbnailCell
        if indexPath.item >= data.count {
            cell.configureTileForSuggestedSite(site as! SuggestedSite)
        } else {
            cell.configureTileForSite(site, isEditing: editingThumbnails, profile: profile)
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if data.status != .Success {
            return 0
        }

        return min(numberOfTilesToDisplay, data.count + SuggestedSites.count)
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

// MARK: Cell Decorators
private extension ThumbnailCell {
    func setDefaultThumbnailBackground() {
        imageView.image = UIImage(named: "defaultTopSiteIcon")!
        imageView.contentMode = UIViewContentMode.Center
    }

    func blurredImage(iconImage: UIImage, forURL url: NSURL) -> UIImage {
        let blurredKey = "\(url.absoluteString)!blurred"
        let blurredImage: UIImage
        if let cachedImage = SDImageCache.sharedImageCache().imageFromDiskCacheForKey(blurredKey) {
            blurredImage = cachedImage
        } else {
            blurredImage = iconImage.applyLightEffect()
            SDImageCache.sharedImageCache().storeImage(blurredImage, forKey: blurredKey)
        }
        return blurredImage
    }

    func getFavicon(site: Site, profile: Profile) {
        setDefaultThumbnailBackground()
        guard let url = site.url.asURL else { return }

        FaviconFetcher.getForURL(url, profile: profile) >>== { icons in
            if icons.count == 0 { return }
            guard let url = icons[0].url.asURL else { return }

            self.imageView.sd_setImageWithURL(url) { (img, err, type, url) -> Void in
                guard let img = img else {
                    let icon = Favicon(url: "", date: NSDate(), type: IconType.NoneFound)
                    profile.favicons.addFavicon(icon, forSite: site)
                    self.setDefaultThumbnailBackground()
                    return
                }

                self.image = img
                self.backgroundImage.image = self.blurredImage(img, forURL: url)
            }
        }
    }

    func configureTileForSite(site: Site, isEditing editing: Bool, profile: Profile) {

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
        textLabel.text = domainURL
        accessibilityLabel = textLabel.text
        removeButton.hidden = !editing

        guard let icon = site.icon else {
            getFavicon(site, profile: profile)
            return
        }

        // We've looked before recently and didn't find a favicon
        switch icon.type {
        case .NoneFound where NSDate().timeIntervalSinceDate(icon.date) < FaviconFetcher.ExpirationTime:
            self.setDefaultThumbnailBackground()
        default:
            imageView.sd_setImageWithURL(icon.url.asURL, completed: { (img, err, type, url) -> Void in
                if let img = img {
                    self.image = img
                    self.backgroundImage.image = self.blurredImage(img, forURL: url)
                } else {
                    self.getFavicon(site, profile: profile)
                }
            })
        }
    }

    func configureTileForSuggestedSite(site: SuggestedSite) {
        textLabel.text = site.title.isEmpty ? NSURL(string: site.url)?.normalizedHostAndPath() : site.title
        imageWrapper.backgroundColor = site.backgroundColor
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        accessibilityLabel = textLabel.text

        guard let icon = site.wordmark.url.asURL,
              let host = icon.host else {
            self.setDefaultThumbnailBackground()
            return
        }

        if icon.scheme == "asset" {
            imageView.image = UIImage(named: host)
        } else {
            imageView.sd_setImageWithURL(icon, completed: { img, err, type, key in
                if img == nil {
                    self.setDefaultThumbnailBackground()
                }
            })
        }
    }
}
