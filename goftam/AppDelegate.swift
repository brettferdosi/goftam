//
//  AppDelegate.swift
//  goftam
//
//  Created by Brett Gutstein on 5/1/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

import Cocoa
import InputMethodKit

// global scope

// only need one candidates window for the entire input method because
// only one such window should be visible at a time
var candidatesWindow: IMKCandidates = IMKCandidates()
var goftamTransliterator: GoftamTransliterator = PersianGoftamTransliterator()
var bypassTransliteration: Bool = false // global option to bypass transliteration

func toggleBypass() {
    goftamLog("setting bypass from \(bypassTransliteration) to \(!bypassTransliteration)")
    bypassTransliteration = !bypassTransliteration
}

func goftamLog(_ format: String, caller: String = #function, args: CVarArg...) {
    NSLog("goftam: \(caller) " + format, args)
}

// app delegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        goftamLog("")

        // no matter what Info.plist and goftam.entitlements say, the connection name
        // requested from the sandbox seems to be $(PRODUCT_BUNDLE_IDENTIFIER)_Connection,
        // so Info.plist and goftam.entitlements have been set to comply with this choice
        let server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String,
                               bundleIdentifier: Bundle.main.bundleIdentifier)

        // scrolling to the bottom of the scrolling panel puts selection numbers out of alignment
        candidatesWindow = IMKCandidates(server: server,
                                         panelType: kIMKSingleColumnScrollingCandidatePanel)
                                         //panelType: kIMKSingleRowSteppingCandidatePanel)

        // as of 10.15.3, default candidates window key event handling is buggy
        // (number selector keys don't work). workaround involves bypassing default window handling.
        candidatesWindow.setAttributes([IMKCandidatesSendServerKeyEventFirst : NSNumber(booleanLiteral: true)])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        goftamLog("")
    }

}

