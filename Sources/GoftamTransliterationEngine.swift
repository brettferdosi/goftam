//
//  GoftamTransliterationEngine.swift
//  goftam
//
//  Created by Brett Gutstein on 5/9/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

// transliteration rules can apply at the beginning, middle, and end of a word
// by using the flags in this OptionSet
struct GoftamTransliterationRuleType: OptionSet {

    let rawValue: UInt8
    // beginning applies only as the first rule in the word
    static let beginning = GoftamTransliterationRuleType(rawValue: 1 << 0)
    // middle applies as neither the first nor the last rule in the word
    static let middle = GoftamTransliterationRuleType(rawValue: 1 << 1)
    // end applies only as the last rule in the word
    static let end = GoftamTransliterationRuleType(rawValue: 1 << 2)

}

// a transliteration rule that replaces input characters with
// output characters and is only context-sensitive to whether it
// is applied at the beginning middle or end of the word
struct GoftamTransliterationRule {

    var _type: GoftamTransliterationRuleType // where does the rule apply
    var _inputChars: String // what input character does the rule take
    var _outputChars: String // what output characters does the rule produce

    init(_ type: GoftamTransliterationRuleType,_ inputChars: String,_ outputChars: String) {
        self._type = type
        self._inputChars = inputChars
        self._outputChars = outputChars
    }

}

// engine that builds a state machine based on transliteration rules
// (which consume matching input characters as they are applied) and then can
// process input strings to give all possible rule-based transliterations
class GoftamTransliterationEngine {

    // trick to have an ordered list with no duplicates because
    // Swift doesn't have an ordered set
    private class OrderedSet<T: Hashable>: Sequence {

        private var _set: Set<T>
        private var _list: Array<T>

        init() {
            self._set = Set<T>()
            self._list = []
        }

        @discardableResult func insert(_ newMember: T) -> Bool {
            let inserted = self._set.insert(newMember).inserted
            if inserted {
                self._list.append(newMember)
            }
            return inserted
        }
        
        func getList() -> Array<T> {
            return self._list
        }

        func makeIterator() -> Array<T>.Iterator {
            return self._list.makeIterator()
        }

    }

    // trick to store tuples in our ordered set because
    // Swift does not have good tuples
    private class HashablePair<T1, T2>: Hashable where T1: Hashable, T2: Hashable {

        var _first: T1
        var _second: T2

        init(_ first: T1,_ second: T2) {
            self._first = first
            self._second = second
        }

        static func == (lhs: GoftamTransliterationEngine.HashablePair<T1, T2>, rhs: GoftamTransliterationEngine.HashablePair<T1, T2>) -> Bool {
            return (lhs._first == rhs._first) && (lhs._second == rhs._second)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self._first)
            hasher.combine(self._second)
        }

    }

    // transition between states
    private class TransliterationStateTransition: Equatable, Hashable {

        var _outputChars: String // characters to add to the transliteration when the transition is taken
        var _nextState: TransliterationState? // the state to transition to

        init(_ outputChars: String,_ nextState: TransliterationState?) {
            self._outputChars = outputChars
            self._nextState = nextState
        }

        static func ==(lhs: TransliterationStateTransition, rhs: TransliterationStateTransition) -> Bool {
            return (lhs._outputChars == rhs._outputChars) && (lhs._nextState == rhs._nextState)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self._outputChars)
            hasher.combine(self._nextState)
        }

    }

    // a state in the engine's state machine
    private class TransliterationState: Equatable, Hashable {

        // from a given state, the current input character is used to determine
        // the transitions that apply. transitions to auxiliary states, which
        // are used to handle multi-input-character rules as discussed below,
        // all have the empty string as their output characters. because all
        // transitions to auxiliary states have the same output characters,
        // a single auxiliary state can be used per input character. the
        // current state's auxiliary state for a given input character, if it
        // exists, is also stored in the transition map.
        var _transitionMap:
            Dictionary<Character,(auxiliaryState: TransliterationState?, transitions: OrderedSet<TransliterationStateTransition>)> =
            Dictionary<Character, (TransliterationState?, OrderedSet<TransliterationStateTransition>)>()
 
        // states are only equal if they're the same exact state
        // (classes are passed by reference in Swift even though structs are not)
        static func ==(lhs: TransliterationState, rhs: TransliterationState) -> Bool {
            return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }

        // add a transition from this state to some other given state
        func addTransition(_ to: TransliterationState?,_ input: Character,_ output: String) {
            // if there are no transitions for the given input character, create the set to hold them
            if self._transitionMap[input] == nil {
                self._transitionMap[input] = (nil, OrderedSet<TransliterationStateTransition>())
            }

            // otherwise just insert the transition, set handles duplicates
            self._transitionMap[input]!.transitions.insert(TransliterationStateTransition(output, to))
        }

        // add a transition from this state to its auxiliary state for the given input character
        func addTransitionToAuxiliary(_ input: Character) -> TransliterationState {
            // if there are no transitions for the given input character, create the set to hold them
            if self._transitionMap[input] == nil {
                self._transitionMap[input] = (nil, OrderedSet<TransliterationStateTransition>())
            }

            let auxiliaryState = self._transitionMap[input]!.auxiliaryState

            // if the auxiliary state is already present, simply return it
            // because the appropriate transition has already been added
            if auxiliaryState != nil {
                return auxiliaryState!

            // if the auxiliary state is not present, create a new auxiliary
            // state and add the appropriate transition to it
            } else {
                let newAuxiliaryState = TransliterationState()
                self._transitionMap[input]!.auxiliaryState = newAuxiliaryState
                self._transitionMap[input]!.transitions.insert(TransliterationStateTransition("", newAuxiliaryState))
                return newAuxiliaryState
            }
        }

    }

    // the engine has a beginning state from which transliteration starts,
    // a middle state to which non-terminal transliteration rules return,
    // auxiliary states that are used to facilitate the processing of
    // multi-input-character rules, and terminal states represented by nil

    private var _beginningState: TransliterationState
    private var _middleState: TransliterationState
    
    // BFG: could add a pass to minimize states, but it may not be necessary.
    // the order of rules affects the order of outputted transliterations;
    // the outputted transliterations look depth-first-search-like relative
    // to the rule order (see transliterate())
    init(_ rules: [GoftamTransliterationRule]) {
        self._beginningState = TransliterationState()
        self._middleState = TransliterationState()
        for rule in rules {
            addRule(rule)
        }
    }

    // add a rule to the transliteration engine
    private func addRule(_ rule: GoftamTransliterationRule) {
        if rule._type.contains(.beginning) {
            // add states for beginning rule that is not the only rule applied
            addRuleHelper(rule, self._beginningState, self._middleState)
            // add states for beginning rule that is the only rule applied
            addRuleHelper(rule, self._beginningState, nil)
        }
        if rule._type.contains(.middle) {
            // add states for middle rule
            addRuleHelper(rule, self._middleState, self._middleState)
        }
        if rule._type.contains(.end) {
            // add states for ending rule that is the only rule applied
            addRuleHelper(rule, self._beginningState, nil)
            // add states for ending rule that is not the only rule applied
            addRuleHelper(rule, self._middleState, nil)
        }
    }

    // given a rule, a start state, and an end state, create intermediate states and
    // transitions between the start and end states so that the rule applies between them
    private func addRuleHelper(_ rule: GoftamTransliterationRule,_ startState: TransliterationState,
                               _ endState: TransliterationState?) {
        let inputChars = rule._inputChars
        var currentState = startState
        for index in inputChars.indices {
            let inputChar = inputChars[index]
            
            // this is the last input character in the rule; add a
            // transition from the current state to the end state
            // based on the input character that contains the rule's
            // output characters
            if inputChars.index(after: index) ==  inputChars.endIndex {
                currentState.addTransition(endState, inputChar, rule._outputChars)

            // this is not the last input character in the rule; add
            // a transition to an auxiliary state based on the input
            // character and proceed to the next input character in the rule
            } else {
                currentState = currentState.addTransitionToAuxiliary(inputChar)
            }
        }
    }

    // BFG: could add support for reusing state across calls, but it may not be necessary.
    // once a transliteration engine has been created based on some rules, a
    // transliteration operation takes in an input string and returns a list
    // of possible transliterations for it. the possible transliterations are
    // determined by maintaining a list of (state, output string) pairs. the
    // input string characters are fed in one-by-one; for each input character,
    // every state in the list is replaced by all possible next-states according
    // to the transition map. the output strings of those next-states have the
    // output characters from the corresponding transitions appended. once all
    // characters from the input string have been processed, the output strings
    // of states in the list that are nil (terminal states) are returned.
    func transliterate(_ input: String) -> [String] {
        var states: OrderedSet<HashablePair<TransliterationState?, String>> = OrderedSet()
        states.insert(HashablePair(self._beginningState, ""))
        for char in input {
            let newStates: OrderedSet<HashablePair<TransliterationState?, String>> = OrderedSet()
            for pair in states {
                let state = pair._first
                let outputString = pair._second
                // if this state is terminal or doesn't have any transitions for
                // the current input character, we have reached a dead end
                if (state == nil) || (state!._transitionMap[char] == nil) {
                    continue
                }
                for transition in state!._transitionMap[char]!.transitions {
                    newStates.insert(HashablePair(transition._nextState, outputString + transition._outputChars))
                }
            }
            states = newStates
        }

        // only return non-trivial output strings corresponding to terminal states
        return states.getList().filter { ($0._first == nil) && ($0._second != "") }.map { $0._second }
    }

}
