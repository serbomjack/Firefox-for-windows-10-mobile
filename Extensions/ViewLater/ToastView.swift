/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private struct UXDefaults {
    static let TitleForegroundColor = UIColor(colorString: "#FFF")
    static let TitleFont = UIFont.systemFontOfSize(15)
    static let BackgroundColor = UIColor(colorString: "#4A4A4A")
    static let SuccessIconBackgroundColor = UIColor(colorString: "#7ED321")
    static let FailureIconBackgroundColor = UIColor.redColor()
    static let IconSize = CGSize(width: 27, height: 22)
    static let IconBackgroundWidth: CGFloat = 60
    static let TitleMargin: CGFloat = 15
    static let CornerRadius: CGFloat = 5
}

public enum ToastDuration: UInt64 {
    case Short = 1
    case Long = 5
}

/// A small toast view with an icon to the left and title label to the right.
public class ToastView: UIView {
    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var iconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UXDefaults.SuccessIconBackgroundColor
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UXDefaults.TitleFont
        label.textColor = UXDefaults.TitleForegroundColor
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        layer.cornerRadius = UXDefaults.CornerRadius

        setupConstraints()
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        iconView.snp_makeConstraints { make in
            make.size.equalTo(UXDefaults.IconSize)
            make.center.equalTo(iconBackground)
        }

        iconBackground.snp_makeConstraints { make in
            make.left.top.bottom.equalTo(self)
            make.width.equalTo(UXDefaults.IconBackgroundWidth)
        }

        titleLabel.snp_makeConstraints { make in
            make.margins.equalTo(UXDefaults.TitleMargin)
            make.centerY.equalTo(self)
            make.left.equalTo(iconView.snp_right)
            make.right.equalTo(self)
        }
    }
}

public extension ToastView {
    class func successToast(text: String) -> ToastView {
        let toast = ToastView()
        toast.titleLabel.text = text
        toast.iconView.image = UIImage(named: "successCheck")
        toast.iconBackground.backgroundColor = UXDefaults.SuccessIconBackgroundColor
        toast.backgroundColor = UXDefaults.BackgroundColor
        return toast
    }

    class func failureToast(text: String) -> ToastView {
        let toast = ToastView()
        toast.titleLabel.text = text
        toast.iconView.image = UIImage(named: "sadFace")
        toast.iconBackground.backgroundColor = UXDefaults.FailureIconBackgroundColor
        toast.backgroundColor = UXDefaults.BackgroundColor
        return toast
    }
}