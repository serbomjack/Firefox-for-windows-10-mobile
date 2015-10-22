/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
  This enum extends the size class idea introduced in iOS 8 with a more granular version that
  factors in the various edge screen sizes available for iOS. In some cases, such as different
  orientations for iPad, the size class is the same regardless of it's orientation. This abstraction
  jallows more control over how to display content for the given window size.
*/
public enum FXSizeClass: Int {
    case SizeUndefined = 0
    case SizeBelow320 = 1
    case Size320 = 2
    case Size375 = 3
    case Size414 = 4
    case Size480 = 5
    case Size568 = 6
    case Size667 = 7
    case Size736 = 8
    case Size768 = 9
    case Size1024 = 10
    case Size1366AndAbove = 11

    static func sizeClassFromLength(length: CGFloat) -> FXSizeClass {
        switch length {
        case let l where l < 0:
            return SizeUndefined
        case 0..<320:
            return SizeBelow320
        case 320..<375:
            return Size320
        case 375..<414:
            return Size375
        case 414..<480:
            return Size414
        case 480..<568:
            return Size480
        case 568..<667:
            return Size568
        case 667..<736:
            return Size667
        case 736..<768:
            return Size736
        case 768..<1024:
            return Size768
        case 1024..<1366:
            return Size1024
        case let l where l >= 1366:
            return Size1366AndAbove
        default:
            return SizeUndefined
        }
    }
}

extension FXSizeClass: ForwardIndexType {
    public func successor() -> FXSizeClass {
        return FXSizeClass(rawValue: self.rawValue + 1)
    }
}

extension FXSizeClass: CustomStringConvertible {
    public var description: String {
        switch self {
        case SizeUndefined:     return "Undefined"
        case SizeBelow320:      return "< 320"
        case Size320:           return "320 -> 374 (iPhone 4/5 Width)"
        case Size375:           return "375 -> 413 (iPhone 6 Width)"
        case Size414:           return "414 -> 479 (iPhone 6+ Width)"
        case Size480:           return "480 -> 567 (iPhone 4 Height)"
        case Size568:           return "568 -> 666 (iPhone 5 Height)"
        case Size667:           return "667 -> 735 (iPhone 6 Height)"
        case Size736:           return "736 -> 767 (iPhone 6+ Height)"
        case Size768:           return "768 -> 1023 (iPad Mini/Air Width)"
        case Size1024:          return "1024 -> 1365 (iPad Mini/Air Height)"
        case Size1366AndAbove:  return ">= 1366 (iPad Pro Height)"
        }
    }
}

/**
  Extending UITraitEnvironment allows anything that would have a UITraitCollection/size class to
  have a FXSizeClass as well.
*/
extension UITraitEnvironment {
    private func sizeClassForAxis(axis: UILayoutConstraintAxis) -> FXSizeClass {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let rootWindow = appDelegate.window {
            switch axis {
            case .Horizontal:
                return FXSizeClass.sizeClassFromLength(rootWindow.bounds.width)
            case .Vertical:
                return FXSizeClass.sizeClassFromLength(rootWindow.bounds.height)
            }
        } else {
            return .SizeUndefined
        }
    }

    var fx_horizontalSizeClass: FXSizeClass {
        return sizeClassForAxis(.Horizontal)
    }

    var fx_verticalSizeClass: FXSizeClass {
        return sizeClassForAxis(.Vertical)
    }
}
