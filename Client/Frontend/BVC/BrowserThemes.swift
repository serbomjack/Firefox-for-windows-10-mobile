/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// TODO: Update header/footer backgrounds when theme changes for tab view
// Probably move these properties into configurable properties of the BrowserView
struct BrowserThemes {
    static func applyPrivateModeTheme() {
        BrowserLocationView.appearance().baseURLFontColor = UIColor.lightGrayColor()
        BrowserLocationView.appearance().hostFontColor = UIColor.whiteColor()
        BrowserLocationView.appearance().backgroundColor = UIConstants.PrivateModeLocationBackgroundColor

        ToolbarTextField.appearance().backgroundColor = UIConstants.PrivateModeLocationBackgroundColor
        ToolbarTextField.appearance().textColor = UIColor.whiteColor()
        ToolbarTextField.appearance().clearButtonTintColor = UIColor.whiteColor()
        ToolbarTextField.appearance().highlightColor = UIConstants.PrivateModeTextHighlightColor

        URLBarView.appearance().locationBorderColor = UIConstants.PrivateModeLocationBorderColor
        URLBarView.appearance().locationActiveBorderColor = UIConstants.PrivateModePurple
        URLBarView.appearance().progressBarTint = UIConstants.PrivateModePurple
        URLBarView.appearance().cancelTextColor = UIColor.whiteColor()
        URLBarView.appearance().actionButtonTintColor = UIConstants.PrivateModeActionButtonTintColor

        BrowserToolbar.appearance().actionButtonTintColor = UIConstants.PrivateModeActionButtonTintColor

        TabsButton.appearance().borderColor = UIConstants.PrivateModePurple
        TabsButton.appearance().borderWidth = 1
        TabsButton.appearance().titleFont = UIConstants.DefaultMediumBoldFont
        TabsButton.appearance().titleBackgroundColor = UIConstants.AppBackgroundColor
        TabsButton.appearance().textColor = UIConstants.PrivateModePurple
        TabsButton.appearance().insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        ReaderModeBarView.appearance().backgroundColor = UIConstants.PrivateModeReaderModeBackgroundColor
        ReaderModeBarView.appearance().buttonTintColor = UIColor.whiteColor()

//        header.blurStyle = .Dark
//        footerBackground?.blurStyle = .Dark
    }

    static func applyNormalModeTheme() {
        BrowserLocationView.appearance().baseURLFontColor = BrowserLocationViewUX.BaseURLFontColor
        BrowserLocationView.appearance().hostFontColor = BrowserLocationViewUX.HostFontColor
        BrowserLocationView.appearance().backgroundColor = UIColor.whiteColor()

        ToolbarTextField.appearance().backgroundColor = UIColor.whiteColor()
        ToolbarTextField.appearance().textColor = UIColor.blackColor()
        ToolbarTextField.appearance().highlightColor = AutocompleteTextFieldUX.HighlightColor
        ToolbarTextField.appearance().clearButtonTintColor = nil

        URLBarView.appearance().locationBorderColor = URLBarViewUX.TextFieldBorderColor
        URLBarView.appearance().locationActiveBorderColor = URLBarViewUX.TextFieldActiveBorderColor
        URLBarView.appearance().progressBarTint = URLBarViewUX.ProgressTintColor
        URLBarView.appearance().cancelTextColor = UIColor.blackColor()
        URLBarView.appearance().actionButtonTintColor = UIColor.darkGrayColor()

        BrowserToolbar.appearance().actionButtonTintColor = UIColor.darkGrayColor()

        TabsButton.appearance().borderColor = TabsButtonUX.BorderColor
        TabsButton.appearance().borderWidth = TabsButtonUX.BorderStrokeWidth
        TabsButton.appearance().titleFont = TabsButtonUX.TitleFont
        TabsButton.appearance().titleBackgroundColor = TabsButtonUX.TitleBackgroundColor
        TabsButton.appearance().textColor = TabsButtonUX.TitleColor
        TabsButton.appearance().insets = TabsButtonUX.TitleInsets

        ReaderModeBarView.appearance().backgroundColor = UIColor.whiteColor()
        ReaderModeBarView.appearance().buttonTintColor = UIColor.darkGrayColor()

//        header.blurStyle = .ExtraLight
//        footerBackground?.blurStyle = .ExtraLight
    }
}