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

// the transliterator to use and whether or not to
// bypass it are global options, even though changes
// are made from particular GoftamIMKInputController objects
var goftamTransliterator: GoftamTransliterator = PersianGoftamTransliterator()
// identifier for the transliterator's input mode, from Info.plist
var goftamTransliteratorName: String = "goftampersian"
var bypassTransliteration: Bool = false

// :selectMode() will call GoftamIMKInputController:setValue(),
// which in turn will call selectTransliterator() below and
// change the bypass boolean appropraitely. if either the bypass
// input mode or the main language input modes are not loaded,
// this design will fail gracefully because :selectMode() will not
// cause :setValue() to be called.
func toggleBypass(_ client: (IMKTextInput & IMKUnicodeTextInput)) {
    if (bypassTransliteration) {
        // switch to the non-bypassed version of the current input mode
        client.selectMode(goftamTransliteratorName)
    } else {
        // switch to the bypass input mode
        client.selectMode("goftambypass")
    }
}

// select the transliterator to use (or enable bypass mode) by
// its input mode name (from ComponentInputModeDict in Info.plist)
func selectTransliterator(_ mode: String) {
    goftamLog("mode \(mode)")
    switch mode {
    case "goftambypass":
        bypassTransliteration = true
    case "goftampersian":
        bypassTransliteration = false
        goftamTransliterator = PersianGoftamTransliterator()
        goftamTransliteratorName = "goftampersian"
    default:
        goftamLog("invalid transliterator selected")
        abort()
    }
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

