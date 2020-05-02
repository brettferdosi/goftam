//
//  AppDelegate.swift
//  goftam
//
//  Created by Brett Gutstein on 5/1/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

import Cocoa
import InputMethodKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("goftam: launching")

        // the name of the connection seems to be chosen for us as $(PRODUCT_BUNDLE_IDENTIFIER)_Connection.
        // Info.plist and goftam.entitlements comply with this choice.
        let _ = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String,
                           bundleIdentifier: Bundle.main.bundleIdentifier)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

}

