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

// only need one candidates window for the entire input method
// because only one such window should be visible at a time
var candidatesWindow: IMKCandidates = IMKCandidates()
var wordStore: GoftamWordStore = GoftamWordStore()

// transliterator selection and control

// mapping from input mode names (from ComponentInputModeDict
// in Info.plist) to transliterator objects
var transliterators: Dictionary<String, GoftamTransliterator> =
    [PersianGoftamTransliterator.transliteratorName: PersianGoftamTransliterator()]

// BFG: different default behavior when more languages added?
var activeTransliterator: GoftamTransliterator =
    transliterators[PersianGoftamTransliterator.transliteratorName]!

// bypass control
var bypassTransliteration: Bool = false
var bypassTransliteratorName: String = "goftambypass"

// select the transliterator to use (or enable bypass mode) by
// its input mode name (from ComponentInputModeDict in Info.plist)
func selectTransliterator(_ mode: String) {
    goftamLog(logLevel: .VERBOSE, "mode \(mode)")
    if mode == bypassTransliteratorName {
        bypassTransliteration = true
    } else {
        guard let transliterator = transliterators[mode] else {
            goftamLog("invalid transliterator selected")
            abort()
        }
        bypassTransliteration = false
        activeTransliterator = transliterator
    }
}

// logging

enum GoftamLogLevel: Int {
    case VERBOSE = 0
    case ALWAYS_PRINT
}
let currentGoftamLogLevel: GoftamLogLevel = .ALWAYS_PRINT
func goftamLog(logLevel: GoftamLogLevel = .ALWAYS_PRINT, _ format: String,
               file: String = #file, caller: String = #function, args: CVarArg...) {
    if (logLevel.rawValue >= currentGoftamLogLevel.rawValue) {
        let fileName = file.components(separatedBy: "/").last ?? ""
        NSLog("\(fileName):\(caller) " + format, args)
    }
}

// app delegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let version: String =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let buildNumber: String =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        goftamLog("version \(version) (\(buildNumber))")

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

