/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

import Shared
import Storage
import SnapKit

@objc(ViewLaterViewController)
class ViewLaterViewController: UIViewController {
    lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(colorString: "#FFF")
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: {
            (item, error) -> Void in
            if error == nil && item != nil {
                let profile = BrowserProfile(localName: "profile", app: nil)
                profile.queue.addToQueue(item!)
                self.showToast(ToastView.successToast(NSLocalizedString("Success", comment: "Success toast title after selecting View Later")), context: self.extensionContext!)
            } else {
                self.showToast(ToastView.failureToast(NSLocalizedString("Error", comment: "Failure toast title after selecting View Later")), context: self.extensionContext!)
            }
        })
    }

    private func showToast(toastView: ToastView, context: NSExtensionContext) {
        view.addSubview(overlayView)
        view.addSubview(toastView)
        toastView.snp_makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(185)
        }
        overlayView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        toastView.hidden = true
        overlayView.hidden = true
        view.layoutIfNeeded()

        UIView.animateWithDuration(0.3, animations: {
            toastView.hidden = false
            self.overlayView.hidden = false
        }, completion: { _ in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                toastView.removeFromSuperview()
                context.completeRequestReturningItems([], completionHandler: nil);
            }
            return
        })
    }
}