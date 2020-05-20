//
//  PersianGoftamTransliterator.swift
//  goftam
//
//  Created by Brett Gutstein on 5/6/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

class PersianGoftamTransliterator: GoftamTransliterator {

    private let _punctuationMap: Dictionary<Character, Character> = [
        "," : "،",
        ";" : "؛",
        "?" : "؟",
        "<" : "»",
        ">" : "«"
    ]

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
        // BFG: reduce rule list size by eliminating redundancy? e.g. kh and x or u and oo

        GoftamTransliterationRule([.end], "ye", "ی"),
        // dictionary words don't have hamze
        GoftamTransliterationRule([.end], "eye", "هٔ"),
        GoftamTransliterationRule([.end], "aye", "هٔ"), // is this useful?
        GoftamTransliterationRule([.end], "oye", "هٔ"), // is this useful?

        GoftamTransliterationRule([.end], "ei", "ه‌ای"),
        GoftamTransliterationRule([.end], "ii", "ی‌ای"),
        GoftamTransliterationRule([.end], "ai", "ه‌ای"), // is this useful?
        GoftamTransliterationRule([.end], "oi", "ه‌ای"), // is this useful?
        // dictionary words don't have hamze
        GoftamTransliterationRule([.end], "ai", "ائی"),
        GoftamTransliterationRule([.end], "aai", "ائی"),
        GoftamTransliterationRule([.end], "ui", "وئی"),
        GoftamTransliterationRule([.end], "ooi", "وئی"),

        GoftamTransliterationRule([.end], "eha", "ه‌ها"),
        GoftamTransliterationRule([.end], "ehaa", "ه‌ها"),
        GoftamTransliterationRule([.end], "aha", "ه‌ها"), // is this useful?
        GoftamTransliterationRule([.end], "ahaa", "ه‌ها"), // is this useful?
        GoftamTransliterationRule([.end], "oha", "ه‌ها"), // is this useful?
        GoftamTransliterationRule([.end], "ohaa", "ه‌ها"), // is this useful?

        GoftamTransliterationRule([.beginning], "aa", "آ"),
        GoftamTransliterationRule([.middle, .end], "aa", "ا"),
        GoftamTransliterationRule([.beginning, .middle, .end], "ch", "چ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "kh", "خ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "zh", "ژ"),
        GoftamTransliterationRule([.beginning, .middle, .end], "sh", "ش"),
        GoftamTransliterationRule([.beginning, .middle, .end], "gh", "ق"),
        GoftamTransliterationRule([.beginning, .middle, .end], "gh", "غ"),
        GoftamTransliterationRule([.beginning], "oo", "او"),
        GoftamTransliterationRule([.middle, .end], "oo", "و"),
        GoftamTransliterationRule([.end], "an", "اً"),

        GoftamTransliterationRule([.beginning], "a", "ا"),
        GoftamTransliterationRule([.middle, .end], "a", ""),
        GoftamTransliterationRule([.beginning], "a", "آ"),
        GoftamTransliterationRule([.middle, .end], "a", "ا"),
        GoftamTransliterationRule([.end], "a", "ه"),
        GoftamTransliterationRule([.beginning, .middle, .end], "a", "ع"), // is .end useful?

        GoftamTransliterationRule([.beginning, .middle, .end], "b", "ب"),
        GoftamTransliterationRule([.beginning, .middle, .end], "c", "ک"),
        GoftamTransliterationRule([.beginning, .middle, .end], "d", "د"),

        GoftamTransliterationRule([.beginning], "e", "ا"),
        GoftamTransliterationRule([.middle], "e", ""), // adding .end to support ezafe makes results worse
        GoftamTransliterationRule([.end], "e", "ه"),
        GoftamTransliterationRule([.beginning, .middle, .end], "e", "ع"), // is .end useful?

        GoftamTransliterationRule([.beginning, .middle, .end], "f", "ف"),
        GoftamTransliterationRule([.beginning, .middle, .end], "g", "گ"),

        GoftamTransliterationRule([.beginning, .middle, .end], "h", "ه"),
        GoftamTransliterationRule([.beginning, .middle, .end], "h", "ح"),

        GoftamTransliterationRule([.beginning], "i", "ای"),
        GoftamTransliterationRule([.middle, .end], "i", "ی"),
        GoftamTransliterationRule([.beginning, .middle, .end], "j", "ج"),
        GoftamTransliterationRule([.beginning, .middle, .end], "k", "ک"),
        GoftamTransliterationRule([.beginning, .middle, .end], "l", "ل"),
        GoftamTransliterationRule([.beginning, .middle, .end], "m", "م"),
        GoftamTransliterationRule([.beginning, .middle, .end], "n", "ن"),

        GoftamTransliterationRule([.beginning], "o", "ا"),
        GoftamTransliterationRule([.middle, .end], "o", ""),
        GoftamTransliterationRule([.beginning, .middle, .end], "o", "و"),
        GoftamTransliterationRule([.end], "o", "ه"),
        GoftamTransliterationRule([.beginning, .middle, .end], "o", "ع"), // is .end useful?

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

        GoftamTransliterationRule([.beginning, .middle, .end], "khaa", "خوا"),
        GoftamTransliterationRule([.beginning, .middle, .end], "kha", "خوا"),
        GoftamTransliterationRule([.beginning, .middle, .end], "xaa", "خوا"),
        GoftamTransliterationRule([.beginning, .middle, .end], "xa", "خوا"),
    ]

    private let _transliterator: GoftamTransliterationEngine

    //input mode name (from ComponentInputModeDict in Info.plist)
    static var transliteratorName: String = "goftampersian"

    init() {
        self._transliterator = GoftamTransliterationEngine(self._rules)
    }

    func recognizedCharacters() -> Set<Character> {
        return self._recognizedCharacters
    }

    func punctuationMap() -> Dictionary<Character, Character> {
        return self._punctuationMap
    }

    func digitMap() -> Dictionary<Character, Character> {
        return self._digitMap
    }

    func generateCandidates(_ input: String) -> [String] {
        return wordStore.reorder(self._transliterator.transliterate(input.lowercased()),
                                 usingTable: PersianGoftamTransliterator.transliteratorName)
    }

    func wordSelected(word: String) {
        wordStore.incrementTimesSelected(word,
                                         usingTable: PersianGoftamTransliterator.transliteratorName)
    }

}
