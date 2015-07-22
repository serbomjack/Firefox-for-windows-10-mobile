/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

struct TransitionOptions {
    let container: UIView
    let fromView: UIViewController
    let toView: UIViewController
    let duration: NSTimeInterval

    var fromMoving: TransitioningViewProperties? = nil
    var toMoving: TransitioningViewProperties? = nil
}

typealias TransitioningViewProperties = (view: UIView, endFrame: CGRect)

protocol Transitionable {
    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions)
    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions)
    func transitionablePerformHide(transitionable: Transitionable, options: TransitionOptions)
    func transitionablePerformShow(transitionable: Transitionable, options: TransitionOptions)
    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions)
    func movingViewForHiding() -> TransitioningViewProperties?
    func movingViewForShowing() -> TransitioningViewProperties?
}

@objc
class TransitionManager: NSObject, UIViewControllerAnimatedTransitioning  {
    private let show: Bool
    init(show: Bool) {
        self.show = show
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!

        let container = transitionContext.containerView()

        if show {
            container.insertSubview(toView.view, aboveSubview: fromView.view)
        } else {
            container.addSubview(toView.view)
        }

        var options = TransitionOptions(
            container: container,
            fromView: fromView,
            toView: toView,
            duration: transitionDuration(transitionContext),
            fromMoving: nil,
            toMoving: nil)

        if let to = toView as? Transitionable, let from = fromView as? Transitionable {
            options.toMoving = to.movingViewForShowing()
            options.fromMoving = from.movingViewForHiding()

            to.transitionableWillShow(to, options: options)
            from.transitionableWillHide(from, options: options)
            container.layoutIfNeeded()

            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.AllowUserInteraction |  UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                to.transitionablePerformShow(to, options: options)
                from.transitionablePerformHide(from, options: options)
                container.layoutIfNeeded()
            }, completion: { finished in
                to.transitionableWillComplete(to, options: options)
                from.transitionableWillComplete(from, options: options)
                transitionContext.completeTransition(true)
            })
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 4
    }
}

