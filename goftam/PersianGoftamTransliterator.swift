//
//  PersianGoftamTransliterator.swift
//  goftam
//
//  Created by Brett Gutstein on 5/6/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

class PersianGoftamTransliterator: GoftamTransliterator {

    private let _digitMap: Dictionary<Character, Character> = [
        "0" : "۰",
        "1" : "۱",
        "2" : "۲",
        "3" : "۳",
        "4" : "۴",
        "5" : "۵",
        "6" : "۶",
        "7" : "۷",
        "8" : "۸",
        "9" : "۹"
    ]

    private let _recognizedCharacters: Set<Character> =
        ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
         "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
         "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
         "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
         "'"]

    // rule map inputs should only contain recognized characters;
    // priority order of rules for the same input characters affects transliteration
    private let _rules: [GoftamTransliterationRule] = [
        GoftamTransliterationRule([.beginning, .middle, .end], "khaa", "خوا"),
        GoftamTransliterationRule([.beginning, .middle, .end], "kha", "خوا"),

        GoftamTransliterationRule([.beginning], "aa", "آ"),
        GoftamTransliterationRule([.middle, .end], "aa", "ا"),
        GoftamTransliterationRule([.beginning, .middle, .end], "ch", "چ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "kh", "خ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "zh", "ژ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "sh", "ش"),
        GoftamTransliterationRule([.beginning, .middle, .end], "gh", "غ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "gh", "ق"),
        GoftamTransliterationRule([.beginning], "oo", "او"),
        GoftamTransliterationRule([.middle, .end], "oo", "و"),
        GoftamTransliterationRule([.end], "an", "اً"), // maybe move to end

        GoftamTransliterationRule([.beginning], "a", "ا"),
        GoftamTransliterationRule([.middle, .end], "a", ""),
        GoftamTransliterationRule([.beginning], "a", "آ"), // ? maybe remove
        GoftamTransliterationRule([.middle, .end], "a", "ا"), // ? maybe remove
        GoftamTransliterationRule([.beginning], "a", "ع"), // ? maybe remove, maybe beginning and middle

        GoftamTransliterationRule([.beginning, .middle, .end], "b", "ب"),
        GoftamTransliterationRule([.beginning, .middle, .end], "c", "ک"),
        GoftamTransliterationRule([.beginning, .middle, .end], "d", "د"),

        GoftamTransliterationRule([.beginning], "e", "ا"),
        GoftamTransliterationRule([.middle], "e", ""),
        GoftamTransliterationRule([.end], "e", "ه"),
        GoftamTransliterationRule([.beginning], "e", "ع"), // ? maybe remove, maybe beginning and middle

        GoftamTransliterationRule([.beginning, .middle, .end], "f", "ف"),
        GoftamTransliterationRule([.beginning, .middle, .end], "g", "گ"),

        GoftamTransliterationRule([.beginning, .middle, .end], "h", "ح"),
        GoftamTransliterationRule([.beginning, .middle, .end], "h", "ه"),

        GoftamTransliterationRule([.beginning], "i", "ای"),
        GoftamTransliterationRule([.middle, .end], "i", "ی"),
        GoftamTransliterationRule([.beginning, .middle, .end], "j", "ج"),
        GoftamTransliterationRule([.beginning, .middle, .end], "k", "ک"),
        GoftamTransliterationRule([.beginning, .middle, .end], "l", "ل"),
        GoftamTransliterationRule([.beginning, .middle, .end], "m", "م"),
        GoftamTransliterationRule([.beginning, .middle, .end], "n", "ن"),

        GoftamTransliterationRule([.beginning], "o", "ا"),
        GoftamTransliterationRule([.middle, .end], "o", ""),
        //GoftamTransliterationRule([.beginning], "o", "او"), // ? maybe remove
        GoftamTransliterationRule([.middle], "o", "و"), // ? maybe remove or expand
        GoftamTransliterationRule([.beginning], "o", "ع"), // ? maybe remove, maybe beginning and middle

        GoftamTransliterationRule([.beginning, .middle, .end], "p", "پ"),

        GoftamTransliterationRule([.beginning, .middle, .end], "q", "ق"),
        GoftamTransliterationRule([.beginning, .middle, .end], "q", "غ"),

        GoftamTransliterationRule([.beginning, .middle, .end], "r", "ر"),

        GoftamTransliterationRule([.beginning, .middle, .end], "s", "س"),
        GoftamTransliterationRule([.beginning, .middle, .end], "s", "ص"),
        GoftamTransliterationRule([.beginning, .middle, .end], "s", "ث"),

        GoftamTransliterationRule([.beginning, .middle, .end], "t", "ت"),
        GoftamTransliterationRule([.beginning, .middle, .end], "t", "ط"),

        GoftamTransliterationRule([.beginning], "u", "او"),
        GoftamTransliterationRule([.middle, .end], "u", "و"),
        GoftamTransliterationRule([.beginning, .middle, .end], "v", "و"),
        GoftamTransliterationRule([.beginning, .middle, .end], "w", "و"),
        GoftamTransliterationRule([.beginning, .middle, .end], "x", "خ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "y", "ی"),

        GoftamTransliterationRule([.beginning, .middle, .end], "z", "ز"),
        GoftamTransliterationRule([.beginning, .middle, .end], "z", "ذ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "z", "ظ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "z", "ض"),

        GoftamTransliterationRule([.beginning, .middle, .end], "'", "ع"),
    ]

    private let _transliterator: GoftamTransliterationEngine

    init() {
        self._transliterator = GoftamTransliterationEngine(self._rules)
    }

    func recognizedCharacters() -> Set<Character> {
        return self._recognizedCharacters
    }

    func digitMap() -> Dictionary<Character, Character> {
        return self._digitMap
    }

    // maybe create set then go to list so no duplicates? but maybe order matters
    func generateCandidates(_ input: String) -> [String] {
        var candidates = self._transliterator.transliterate(input.lowercased())
        // ensure that the typed text appears on the first page of the
        // scrolling view (TODO possibly replace with shift-space bypass)
        if (candidates.count > 8) {
            candidates.insert(input, at: 8)
        } else {
            candidates.append(input)
        }
        return candidates
    }

}
