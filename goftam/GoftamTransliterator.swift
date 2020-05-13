//
//  GoftamTransliterator.swift
//  goftam
//
//  Created by Brett Gutstein on 5/11/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

protocol GoftamTransliterator {
    func digitMap() -> Dictionary<Character, Character>
    // the set returned by recognizedCharacters() should
    // not contain digits as recognized by digitMap()
    func recognizedCharacters() -> Set<Character>
    // input to generateCandidates() should only contain
    // characters recognized by recognizedCharacters()
    func generateCandidates(_ input: String) -> [String]
}
