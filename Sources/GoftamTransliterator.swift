//
//  GoftamTransliterator.swift
//  goftam
//
//  Created by Brett Gutstein on 5/11/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

protocol GoftamTransliterator {
    // should be the identifier from the transliterator's input mode from Info.plist
    static var transliteratorName: String { get }

    func punctuationMap() -> Dictionary<Character, Character>
    func digitMap() -> Dictionary<Character, Character>
    // the set returned by recognizedCharacters() should
    // not contain characters recognized by digitMap()
    // or punctuationMap()
    func recognizedCharacters() -> Set<Character>
    // input to generateCandidates() should only contain
    // characters recognized by recognizedCharacters()
    func generateCandidates(_ input: String) -> [String]
    // called when a word is selected by the user
    func wordSelected(word: String)
}
