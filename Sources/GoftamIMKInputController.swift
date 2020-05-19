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

    private static let escapeCharacter: Int = 0x1b // int corresponding to Unicode value of escape
    private static let ZWNJCharacter: Int = 0x200c // int correspoding to Unicode value of ZWNJ
    private static let digitChars: Set<Character> = ["0", "1", "2" ,"3", "4", "5", "6", "7", "8", "9"]
    private static let candidatesTimeoutSeconds: Double = 0.05 // how many seconds to allow for generating candidates

    private var _originalString: String = "" // what the user typed
    private var _composedString: String = "" // currently selected transliteration candidate
    private var _candidates: [String] = [] // list of candidates to choose from
    private var _candidatesTimeoutInput : String = "" // input that caused generating candidates to time out

    // handle system events

    // called once per client the first time it gets focus
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        goftamLog(logLevel: .VERBOSE, "client \(String(describing: inputClient))")
        super.init(server: server, delegate: delegate, client: inputClient)
    }

    // called when the client loses focus
    override func deactivateServer(_ sender: Any!) {
        goftamLog(logLevel: .VERBOSE, "client \(String(describing: sender))")
        commitComposition(sender)
    }

    // called when the client gains focus
    override func activateServer(_ sender: Any!) {
        goftamLog(logLevel: .VERBOSE, "client \(String(describing: sender))")
        // the user may have been changing keyboard layouts while we were deactivated
        // (but the controller survives so init() may not be called again).
        // goftam will use the most recent ASCII capable keyboard layout to translate key
        // events (see TextInputSources.h:TISSetInputMethodKeyboardLayoutOverride()).
        // set the candidates window to use the same keyboard layout.
        let lastASCIIlayout = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        candidatesWindow.setSelectionKeysKeylayout(lastASCIIlayout)
    }

    // called when an input mode is selected; the input mode's
    // identifier (from ComponentInputModeDict in Info.plist) is the
    // value and kTextServiceInputModePropertyTag is the tag
    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        goftamLog(logLevel: .VERBOSE, "value \(String(describing: value)) tag \(tag)")
        if tag == kTextServiceInputModePropertyTag {
            commitComposition(sender)
            selectTransliterator(value as! String)
        } else {
            goftamLog("unhandled tag \(tag)")
            super.setValue(value, forTag: tag, client: sender)
        }
    }

    // generate inputmethod menu and handle user clicks
    override func menu() -> NSMenu! {
        goftamLog(logLevel: .VERBOSE, "")
        let menu = NSMenu()
        if !bypassTransliteration {
            menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory(_:)), keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAboutPanel(_:)), keyEquivalent: "")) // todo build id
        return menu
    }

    @objc private func clearHistory(_ sender: Any) {
        goftamLog(logLevel: .VERBOSE, "")
        wordStore.clearHistory(usingTable: type(of: activeTransliterator).transliteratorName)
    }

    @objc private func showAboutPanel(_ sender: Any) {
        goftamLog(logLevel: .VERBOSE, "")

        let github = NSMutableAttributedString(string: "https://github.com/brettferdosi/goftam")
        github.addAttribute(.link, value: "https://github.com/brettferdosi/goftam",
                            range: NSRange(location: 0, length: github.length))

        let website = NSMutableAttributedString(string: "https://brett.gutste.in")
        website.addAttribute(.link, value: "https://brett.gutste.in",
                             range: NSRange(location: 0, length: website.length))

        let credits = NSMutableAttributedString(string:"")
        credits.append(github)
        credits.append(NSMutableAttributedString(string: "\n"))
        credits.append(website)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        credits.addAttribute(.paragraphStyle, value: paragraphStyle,
                             range: NSRange(location: 0, length: credits.length))

        // setting the activation policy and calling activate() doesn't
        // make our app visible on the dock or make a blank window appear,
        // but it allows our about panel to display in front of other apps
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [ .credits : credits ])
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
    private func toChar(_ unicodeInt: Int) -> Character {
        return Character(UnicodeScalar(unicodeInt) ?? UnicodeScalar(0))
    }

    // handle deficiencies in the swift API: untyped senders should cast successfully
    private func downcastSender(_ sender: Any!) -> (IMKTextInput & IMKUnicodeTextInput) {
        guard let downcast = sender as? (IMKTextInput & IMKUnicodeTextInput) else {
            goftamLog("sender \(String(describing: sender)) did not downcast, trying client()")
            return client() as! (IMKTextInput & IMKUnicodeTextInput)
        }
        return downcast
    }

    // insert marked text at the cursor
    private func writeMarkToClient(_ client: (IMKTextInput & IMKUnicodeTextInput),_ string: String) {
        client.setMarkedText(string,
                             selectionRange: NSMakeRange(0, string.count),
                             replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }

    // insert text at the cursor, overwriting marked text that may be there
    private func writeTextToClient(_ client: (IMKTextInput & IMKUnicodeTextInput),_ string: String) {
        client.insertText(string, replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }

    // output to client

    // commit the current transliteration
    override func commitComposition(_ sender: Any!) {
        goftamLog(logLevel: .VERBOSE, "composed string \(String(describing: self._composedString))")

        writeTextToClient(downcastSender(sender), self._composedString)

        self._originalString = ""
        self._composedString = ""
        self._candidates = []
        self._candidatesTimeoutInput = ""

        candidatesWindow.hide()
    }

    // update mark/candidates for the current transliteration
    override func updateComposition() {
        goftamLog(logLevel: .VERBOSE, "original string \(self._originalString))")

        writeMarkToClient(downcastSender(self.client()), self._originalString)

        // if some previous input string caused generating the candidates to time out,
        // then the list of candidates will be frozen until the present input string
        // becomes shorter than the offending one (which means the user has deleted
        // some characters) or until the composition is committed or cancelled.
        // the marked text continues to update while the candidates list is frozen.
        if self._candidatesTimeoutInput != "" {
            if self._originalString.count < self._candidatesTimeoutInput.count {
                self._candidatesTimeoutInput = ""
            } else {
                return
            }
        }

        // generate candidates asynchronously and write them to a captured local variable,
        // waiting in the main thread for the operation to finish. if the operation times out,
        // then do not use its result and instead freeze the candidates window as described above.
        var candidates: [String] = []

        let work = DispatchWorkItem(block: {
            candidates = activeTransliterator.generateCandidates(self._originalString)
        })
        DispatchQueue.global(qos: .userInitiated).async(execute: work)

        let result = work.wait(wallTimeout: (DispatchWallTime.now() + GoftamIMKInputController.candidatesTimeoutSeconds))
        if result == .timedOut {
            goftamLog("generating candidates for \(self._originalString) using \(activeTransliterator) timed out")
            work.cancel() // this does not actually preempt the work
            self._candidatesTimeoutInput = self._originalString
            return
        }

        self._candidates = candidates

        self._composedString = self._candidates.count > 0 ? self._candidates[0] : ""

        if self._candidates.count == 0 {
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
        goftamLog(logLevel: .VERBOSE, "")

        writeMarkToClient(downcastSender(self.client()), "")

        self._originalString = ""
        self._composedString = ""
        self._candidates = []
        self._candidatesTimeoutInput = ""

        candidatesWindow.hide()
    }

    // input from candidates window

    // user highlighted a selection
    override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        goftamLog(logLevel: .VERBOSE, "selection \(String(describing: candidateString))")
        self._composedString = candidateString.string
    }

    // user made a selection
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        goftamLog(logLevel: .VERBOSE, "selection \(String(describing: candidateString))")
        activeTransliterator.wordSelected(word: candidateString.string)
        self._composedString = candidateString.string
        commitComposition(self.client())
        writeTextToClient(downcastSender(self.client()), " ")
    }

    // input from client

    // handle user actions
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        goftamLog(logLevel: .VERBOSE, "event \(String(describing: event))")
        switch event.type {
        case .keyDown: return handleKeyDown(event, downcastSender(sender))
        default: return false
        }
    }

    // handle user keypress
    private func handleKeyDown(_ event: NSEvent, _ sender: (IMKTextInput & IMKUnicodeTextInput)) -> Bool {
        // goftamLog("")
        let charcount = event.characters?.count
        if charcount != 1 {
            goftamLog("unexpected charcount \(String(describing: charcount))")
            return false
        }
        let char = event.characters!.first!

        // shift-command-space toggles transliteration bypass
        if ((char == " ") && event.modifierFlags.contains([.shift, .command])) {
            // sender.selectMode() will call :selectValue() above with
            // the appropriate tag. if either the bypass input mode
            // or the main language input modes are not loaded, then
            // this design will fail gracefully because selectMode()
            // will not result in a :selectValue() call.
            if bypassTransliteration {
                sender.selectMode(type(of: activeTransliterator).transliteratorName)
            } else {
                sender.selectMode(bypassTransliteratorName)
            }
            return true
        }

        if (bypassTransliteration) {
            return false
        }

        // shift-space maps to ZWNJ for all languages; ends in-progress composition
        if ((char == " ") && event.modifierFlags.contains(.shift)) {
            commitComposition(sender)
            writeTextToClient(sender, String(toChar(GoftamIMKInputController.ZWNJCharacter)))
            return true
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
                //candidatesWindow.interpretKeyEvents([event])
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
        if (activeTransliterator.recognizedCharacters().contains(char)) {
            self._originalString.append(char)
            updateComposition()
            return true

        // recognized digits are translated immediately (there is guaranteed
        // not to be an active composition in this case)
        } else if (activeTransliterator.digitMap().keys.contains(char)) {
            writeTextToClient(sender, String(activeTransliterator.digitMap()[char]!))
            return true

        // keys that are not recognized specifically cause an in-progress
        // composition to be committed and are handled further down the
        // event processing chain. this writes them to the client directly
        //or performs their corresponding actions.
        } else {
            commitComposition(sender)
            return false
        }
    }

}
