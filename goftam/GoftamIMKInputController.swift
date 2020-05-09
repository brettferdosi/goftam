//
//  GoftamIMKInputController.swift
//  goftam
//
//  Created by Brett Gutstein on 5/1/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

import InputMethodKit

class GoftamIMKInputController: IMKInputController {

    // fields and constructor

    static let escapeCharacter : Int = 0x1b
    static let digitChars : Set<Character> = ["0", "1", "2" ,"3", "4", "5", "6", "7", "8", "9"]

    var _originalString : String = "" // what the user typed
    var _composedString : String = "" // the user's current result choice
    var _candidates : [String] = [] // list of candidates to choose from

    // called once per client the first time it gets focus
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        goftamLog("client \(String(describing: inputClient))")
        super.init(server: server, delegate: delegate, client: inputClient)
    }

    // handle client gaining and losing focus

    // called when the client loses focus
    override func deactivateServer(_ sender: Any!) {
        goftamLog("client \(String(describing: sender))")
        if self._composedString.count > 0 {
            commitComposition(sender)
        }
    }

    // called when the client gains focus
    override func activateServer(_ sender: Any!) {
        goftamLog("client \(String(describing: sender))")
        // the user may have been changing keyboard layouts while we were deactivated
        // (but the controller survives so init() may not be called again).
        // goftam will use the most recent ASCII capable keyboard layout to translate key
        // events (see TextInputSources.h:TISSetInputMethodKeyboardLayoutOverride()).
        // set the candidates window to use the same keyboard layout.
        let lastASCIIlayout = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        candidatesWindow.setSelectionKeysKeylayout(lastASCIIlayout)
    }

    // getters

    // called to obtain the composed string
    override func composedString(_ sender: Any!) -> Any! {
        //goftamLog("")
        return self._composedString
    }

    // called to obtain the original string
    override func originalString(_ sender: Any!) -> NSAttributedString! {
        //goftamLog("")
        return NSAttributedString(string: self._originalString)
    }

    // called to obtain the candidates array (used by IMKCandidates:update())
    override func candidates(_ sender: Any!) -> [Any]! {
        //goftamLog("")
        return self._candidates
    }

    // helper functions

    // convert Int representing a Unicode character to a Character
    func toChar(_ unicodeInt: Int) -> Character {
        return Character(UnicodeScalar(unicodeInt) ?? UnicodeScalar(0))
    }

    // handle deficiencies in the swift API: untyped senders should cast successfully
    func downcastSender(_ sender: Any!) -> (IMKTextInput & IMKUnicodeTextInput) {
        guard let downcast = sender as? (IMKTextInput & IMKUnicodeTextInput) else {
            goftamLog("sender \(String(describing: sender)) did not downcast, trying client()")
            return client() as! (IMKTextInput & IMKUnicodeTextInput)
        }
        return downcast
    }

    // insert marked text at the cursor
    func writeMarkToClient(_ client: (IMKTextInput & IMKUnicodeTextInput),_ string: String) {
        client.setMarkedText(string,
                             selectionRange: NSMakeRange(0, string.count),
                             replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }

    // insert text at the cursor, overwriting marked text that may be there
    func writeTextToClient(_ client: (IMKTextInput & IMKUnicodeTextInput),_ string: String) {
        client.insertText(string, replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }

    // output to client

    // commit the current transliteration
    override func commitComposition(_ sender: Any!) {
        goftamLog("composed string \(String(describing: self._composedString))")

        writeTextToClient(downcastSender(sender), self._composedString)

        self._originalString = ""
        self._composedString = ""
        self._candidates = []

        candidatesWindow.hide()
        //candidatesWindow.update()
    }

    // update mark/candidates for the current transliteration
    override func updateComposition() {
        goftamLog("original string \(String(describing: self._originalString))")

        writeMarkToClient(downcastSender(self.client()), _originalString)

        self._candidates = GoftamPersianTranlisterator.generateCandidates(_originalString)

        self._composedString = _candidates[0]

        if self._originalString.count == 0 {
            candidatesWindow.hide()
        } else {
            candidatesWindow.update()
            if !candidatesWindow.isVisible() {
                candidatesWindow.show()
            }
        }
    }

    // cancel the current transliteration
    override func cancelComposition() {
        goftamLog("")

        writeMarkToClient(downcastSender(self.client()), "")

        self._originalString = ""
        self._composedString = ""
        self._candidates = []

        candidatesWindow.hide()
    }

    // input from candidates window

    // user highlighted a selection
    override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        goftamLog("selection \(String(describing: candidateString))")
        self._composedString = candidateString.string
    }

    // user made a selection
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        goftamLog("selection \(String(describing: candidateString))")
        self._composedString = candidateString.string
        commitComposition(self.client())
    }

    // input from client

    // indicate that we support handling more than keypresses - not needed so far
//    override func recognizedEvents(_ sender: Any!) -> Int {
//        goftamLog("")
//        //let events : NSEvent.EventTypeMask = [.any]
//        let events : NSEvent.EventTypeMask = [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]
//        return Int(truncatingIfNeeded: events.rawValue)
//    }

    // handle user actions
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        goftamLog("event \(String(describing: event))")
        switch event.type {
        case .keyDown: return handleKeyDown(event, downcastSender(sender))
        default: return false
        }
    }

    // handle user keypress
    func handleKeyDown(_ event: NSEvent, _ sender: (IMKTextInput & IMKUnicodeTextInput)) -> Bool {
        // goftamLog("")
        let charcount = event.characters?.count
        if charcount != 1 {
            goftamLog("unexpected charcount \(String(describing: charcount))")
            return false
        }
        let char = event.characters!.first!

        // command combinations don't modify transliteration
        // state and should always be passed to the client

        if event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
            return false
        }

        // if the candidates window is open there is a composition in progress

        if candidatesWindow.isVisible() {
            // send relevant keys to the candidates window
            if char == toChar(NSCarriageReturnCharacter) ||
               char == toChar(NSUpArrowFunctionKey) ||
               char == toChar(NSDownArrowFunctionKey) ||
               char == toChar(NSRightArrowFunctionKey) ||
               char == toChar(NSLeftArrowFunctionKey) ||
               GoftamIMKInputController.digitChars.contains(char) {
                // use this private function to workaround buggy candidates
                // window as of 10.15.3
                candidatesWindow.perform(Selector(("handleKeyboardEvent:")), with: event)
                return true

            // backspace is straightforward
            } else if char == toChar(NSBackspaceCharacter) {
                self._originalString = String(self._originalString.dropLast())
                updateComposition()
                return true

            // escape key cancels the composition
            } else if char == toChar(GoftamIMKInputController.escapeCharacter) {
                cancelComposition()
                return true
            }
        }

        // below there is either no composition in progress or there is but the pressed key
        // is not handled by the candidates window

        // a recognized character either starts or continues the composition
        if (GoftamPersianTranlisterator.recognizedCharacters.contains(char)) {
            self._originalString.append(char)
            updateComposition()
            return true

        // recognized digits are translated immediately (there is guaranteed
        // not to be an active composition in this case)
        } else if (GoftamPersianTranlisterator.digitMap.keys.contains(char)) {
            writeTextToClient(sender, String(GoftamPersianTranlisterator.digitMap[char]!))
            return true

        // keys that are not recognized specifically cause an in-progress
        // composition to be committed and are handled further down the
        // event processing chain. this writes them to the client directly
        //or performs their corresponding actions.
        } else {
            if self._originalString.count > 0 {
                commitComposition(sender)
            }
            return false
        }
    }

}
