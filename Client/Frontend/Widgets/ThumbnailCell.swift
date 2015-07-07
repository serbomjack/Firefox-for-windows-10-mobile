/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

struct ThumbnailCellUX {
    /// Ratio of width:height of the thumbnail image.
    static let ImageAspectRatio: Float = 1.0
    static let TextSize = UIConstants.DefaultSmallFontSize
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    static let BorderWidth: CGFloat = 1
    static let LabelFont = UIConstants.DefaultSmallFontMedium
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x353535)
    static let LabelBackgroundColor = UIColor(white: 1.0, alpha: 0.5)
    static let LabelAlignment: NSTextAlignment = .Center
    static let InsetSize: CGFloat = 4
    static let Insets = UIEdgeInsetsMake(InsetSize * 2, InsetSize, InsetSize * 2, InsetSize)
    static let TextOffset = 2
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3

    // Make the remove button look 20x20 in size but have the clickable area be 44x44
    static let RemoveButtonSize: CGFloat = 44
    static let RemoveButtonInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
    static let RemoveButtonAnimationDuration: NSTimeInterval = 0.4
    static let RemoveButtonAnimationDamping: CGFloat = 0.6
}

@objc protocol ThumbnailCellDelegate {
    func didRemoveThumbnail(thumbnailCell: ThumbnailCell)
    func didLongPressThumbnail(thumbnailCell: ThumbnailCell)
}

class ThumbnailCell: UICollectionViewCell {
    weak var delegate: ThumbnailCellDelegate?

    lazy var longPressGesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: "SELdidLongPress")
    }()

    lazy var textWrapper: UIView = {
        let wrapper = UIView()
        wrapper.backgroundColor = ThumbnailCellUX.LabelBackgroundColor
        return wrapper
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = ThumbnailCellUX.LabelFont
        textLabel.textColor = ThumbnailCellUX.LabelColor
        textLabel.textAlignment = ThumbnailCellUX.LabelAlignment
        return textLabel
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFit

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = ThumbnailCellUX.CornerRadius
        return imageView
    }()

    lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.contentMode = UIViewContentMode.ScaleAspectFill
        return backgroundImage
    }()

    lazy var backgroundEffect: UIVisualEffectView = {
        let blur = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let vib = UIVibrancyEffect(forBlurEffect: blur)
        return UIVisualEffectView(effect: blur)
    }()

    lazy var imageWrapper: UIView = {
        let imageWrapper = UIView()
        imageWrapper.layer.borderColor = ThumbnailCellUX.BorderColor.CGColor
        imageWrapper.layer.borderWidth = ThumbnailCellUX.BorderWidth
        imageWrapper.layer.cornerRadius = ThumbnailCellUX.CornerRadius
        imageWrapper.clipsToBounds = true
        return imageWrapper
    } ()

    lazy var removeButton: UIButton = {
        let removeButton = UIButton()
        removeButton.setImage(UIImage(named: "TileCloseButton"), forState: UIControlState.Normal)
        removeButton.addTarget(self, action: "SELdidRemove", forControlEvents: UIControlEvents.TouchUpInside)
        removeButton.hidden = true
        removeButton.imageEdgeInsets = ThumbnailCellUX.RemoveButtonInsets
        return removeButton
    } ()

    override init(frame: CGRect) {
        imagePadding = CGFloat(0)
        super.init(frame: frame)

        isAccessibilityElement = true
        addGestureRecognizer(longPressGesture)

        contentView.addSubview(imageWrapper)
        imageWrapper.addSubview(backgroundImage)
        imageWrapper.addSubview(backgroundEffect)
        imageWrapper.addSubview(imageView)
        imageWrapper.addSubview(textWrapper)
        textWrapper.addSubview(textLabel)
        contentView.addSubview(removeButton)

        imageWrapper.snp_remakeConstraints({ make in
            make.top.bottom.left.right.equalTo(self.contentView).insets(ThumbnailCellUX.Insets)
        })

        backgroundImage.snp_remakeConstraints({ make in
            make.top.bottom.left.right.equalTo(self.imageWrapper)
        })

        backgroundEffect.snp_remakeConstraints({ make in
            make.top.bottom.left.right.equalTo(self.imageWrapper)
        })

        imageView.snp_remakeConstraints({ make in
            make.top.equalTo(self.imageWrapper)
            make.width.equalTo(self.imageView.snp_height)
            make.bottom.equalTo(self.textWrapper.snp_top)
        })

        textWrapper.snp_remakeConstraints({ make in
            make.bottom.equalTo(self.imageWrapper.snp_bottom) // .offset(ThumbnailCellUX.BorderWidth)
            make.left.right.equalTo(self.imageWrapper) // .offset(ThumbnailCellUX.BorderWidth)
        })

        textLabel.snp_remakeConstraints({ make in
            make.edges.equalTo(self.textWrapper).insets(ThumbnailCellUX.Insets)
            return
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // TODO: We can avoid creating this button at all if we're not in editing mode.
        var frame = removeButton.frame
        frame.size = CGSize(width: ThumbnailCellUX.RemoveButtonSize, height: ThumbnailCellUX.RemoveButtonSize)
        frame.center = CGPoint(x: ThumbnailCellUX.InsetSize, y: ThumbnailCellUX.InsetSize)
        removeButton.frame = frame
    }

    func SELdidRemove() {
        delegate?.didRemoveThumbnail(self)
    }

    func SELdidLongPress() {
        delegate?.didLongPressThumbnail(self)
    }

    func toggleRemoveButton(show: Bool) {
        // Only toggle if we change state
        if removeButton.hidden != show {
            return
        }

        if show {
            removeButton.hidden = false
        }

        let scaleTransform = CGAffineTransformMakeScale(0.01, 0.01)
        removeButton.transform = show ? scaleTransform : CGAffineTransformIdentity
        UIView.animateWithDuration(ThumbnailCellUX.RemoveButtonAnimationDuration,
            delay: 0,
            usingSpringWithDamping: ThumbnailCellUX.RemoveButtonAnimationDamping,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions.AllowUserInteraction |  UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.removeButton.transform = show ? CGAffineTransformIdentity : scaleTransform
            }, completion: { _ in
                if !show {
                    self.removeButton.hidden = true
                }
            })
    }

    var imagePadding: CGFloat {
        didSet {
            imageView.snp_remakeConstraints({ make in
                let insets = UIEdgeInsetsMake(imagePadding, imagePadding, imagePadding, imagePadding)
                make.top.left.right.equalTo(self.imageWrapper).insets(insets)
                make.bottom.equalTo(textWrapper.snp_top).offset(-imagePadding) // .insets(insets)
            })
        }
    }

    var image: UIImage? = nil {
        didSet {
            if let image = image {
                imageView.image = image
                imageView.contentMode = UIViewContentMode.ScaleAspectFill
            } else {
                imageView.image = ThumbnailCellUX.PlaceholderImage
                imageView.contentMode = UIViewContentMode.Center
            }
        }
    }
}
