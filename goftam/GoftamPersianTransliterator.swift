//
//  GoftamPersianTransliterator.swift
//  goftam
//
//  Created by Brett Gutstein on 5/6/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

class GoftamPersianTranlisterator {

    // should not contain digits
    static let recognizedCharacters : Set<Character> =
        ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
         "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
         "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
         "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

    static let digitMap : Dictionary<Character, Character> = [
        "0": "۰",
        "1": "۱",
        "2": "۲",
        "3": "۳",
        "4": "۴",
        "5": "۵",
        "6": "۶",
        "7": "۷",
        "8": "۸",
        "9": "۹"
    ]

    // maybe create set then go to list so no duplicates? but maybe order matters
    static func generateCandidates(_ input: String) -> [String] {
        var cands = [input]
        for i in 1...20 {
            cands.append(String(i))
        }
        return cands
    }
}
