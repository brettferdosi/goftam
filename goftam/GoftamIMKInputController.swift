//
//  GoftamIMKInputController.swift
//  goftam
//
//  Created by Brett Gutstein on 5/1/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

import InputMethodKit

class GoftamIMKInputController: IMKInputController {

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        NSLog("goftam: \(String(describing: string))")
        return false
    }

}
