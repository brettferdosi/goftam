//
//  GoftamWordStore.swift
//  goftam
//
//  Created by Brett Gutstein on 5/15/20.
//  Copyright © 2020 Brett Gutstein. All rights reserved.
//

import Foundation
import SQLite3

// this class facilitates interaction with the word store database, located in Resources/goftam.sqlite.
// the database is not writable in the application bundle, so it must be copied to a writeable directory
// before use. each transliterator should create a table in the database of the following form:
// CREATE TABLE goftampersian(word TEXT PRIMARY KEY, inDict BOOLEAN, timesSelected INTEGER);
// where word is a word in the target language, inDict tracks whether the word is in the word
// store dictionary (as opposed to one added by user input), and timesSelected records the
// number of times the word was selected. the table as saved in the source repository
// should only contain dictionary words. the name of the table should be the input mode's identifier
// (from Info.plist).
class GoftamWordStore {
    
    private static let databaseFilename = "goftam.sqlite"

    // table name should be the input mode's identifier
    private var _db: OpaquePointer?
    private var _initSucceeded: Bool

    // make sure the database is copied from the application bundle (not writable)
    // to the application support directory (writable) and establish a connection
    init() {
        let goftamApplicationSupportURL =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)

        if !((try? goftamApplicationSupportURL.checkResourceIsReachable()) ?? false) {
            goftamLog("creating application support directory")

            do {
                try FileManager.default.createDirectory(at: goftamApplicationSupportURL,
                                                        withIntermediateDirectories: true, attributes: nil)
            } catch {
                goftamLog("couldn't create application support directory: \(error)")
                self._initSucceeded = false
                return
            }
        }

        let finalDatabaseURL = goftamApplicationSupportURL.appendingPathComponent(GoftamWordStore.databaseFilename,
                                                                                  isDirectory: false)

        if !((try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
            goftamLog("copying database from bundle to application support")

            let bundleDatabaseURL = Bundle.main.url(forResource: "goftam", withExtension: "sqlite")!

            do {
                try FileManager.default.copyItem(at: bundleDatabaseURL, to: finalDatabaseURL)
            } catch {
                goftamLog("couldn't copy the database: \(error)")
                self._initSucceeded = false
                return
            }
        }

        let status = sqlite3_open(finalDatabaseURL.absoluteString, &self._db)
        if status == SQLITE_OK {
            self._initSucceeded = true
        } else {
            goftamLog("couldn't open connection to the database: \(status)")
            self._initSucceeded = false
        }
    }

    deinit {
        if self._db != nil {
            sqlite3_close(self._db)
        }
    }

    // given a list of words in some order, return a list of the same words reordered based on information
    // from the word store. specifically, previously selected words come first in descending order of the
    // number of times they have been selected; followed by words in the word store (dictionary) that have
    // not been previously selected; followed by words that are not in the word store. ties are broken according
    // to the ordering of words in the input list.
    func reorder(_ input: [String], usingTable tableName: String) -> [String] {
        if (!self._initSucceeded) || (input.count == 0) {
            return input
        }

        // query the backing database to create a mapping of word -> times selected
        // for words in the word store
        let quoted: [String] = input.map {
            var copy = String($0)
            copy.insert("'", at: copy.startIndex)
            copy.append("'")
            return copy
        }
        let wordList = quoted.joined(separator: ",")
        let queryString = "SELECT * FROM " + tableName + " WHERE word IN (" + wordList + ");"
        var queryStatement: OpaquePointer?
        var results: Dictionary<String, Int32> = Dictionary()
        if sqlite3_prepare_v2(self._db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                guard let textResult = sqlite3_column_text(queryStatement, 0) else {
                    goftamLog("error reading a word from the database")
                    continue
                }

                let word = String(cString: textResult)
                let timesSelected = sqlite3_column_int(queryStatement, 2)
                goftamLog(logLevel: .VERBOSE, "read \(word) from database timesSelected \(timesSelected)")
                results[word] = timesSelected
            }
        } else {
            goftamLog("error preparing the query string")
            return input
        }
        sqlite3_finalize(queryStatement)

        // for each word in the input list, cretate a tuple containing the word itself, its index
        // in the input list, and the number of times it has been selected according to the
        // word store (a value of nil for timesSelected means the word was not in the word store)
        var aggregate: [(word: String, originalIndex: Int, timesSelected: Int32?)] = []
        for i in 0..<input.count {
            if results[input[i]] != nil {
                aggregate.append((input[i], i, results[input[i]]))
            } else {
                aggregate.append((input[i], i, nil))
            }
        }

        // sort the aggregated list according to the above criteria
        // (the lambda returns true if the first argument sorts before the second)
        aggregate.sort(by: {
            // $0 and $1 have the same dictionary/selected status; tiebreak on the original index
            if $0.timesSelected == $1.timesSelected {
                return $0.originalIndex < $1.originalIndex

            // $0 was in the dictionary or selected before and $1 was not
            } else if ($0.timesSelected != nil) && ($1.timesSelected == nil) {
                return true

            // both were in the dictionary or selected before but $0 was selected more times
            } else if ($0.timesSelected != nil ) && ($1.timesSelected != nil) &&
                      ($0.timesSelected! > $1.timesSelected!) {
                return true

            } else {
                return false
            }
        })

        return aggregate.map { $0.word }
    }

    func incrementTimesSelected(_ input: String, usingTable tableName: String) {
        if !self._initSucceeded {
            return
        }

        let queryString = "INSERT INTO " + tableName + "(word, inDict, timesSelected) VALUES('" + input + "', 0, 1) "
            + "ON CONFLICT(word) DO UPDATE SET timesSelected = timesSelected + 1"
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(self._db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            if !(sqlite3_step(queryStatement) == SQLITE_DONE) {
                goftamLog("error executing the increment upsert query")
            }
        } else {
            goftamLog("error preparing the query string")
        }
        sqlite3_finalize(queryStatement)
    }

    func clearHistory(usingTable tableName: String) {
        if !self._initSucceeded {
            return
        }

        for queryString in
            ["DELETE FROM " + tableName + " WHERE inDict = 0;",
             "UPDATE " + tableName + " SET timesSelected = 0;"] {

            var queryStatement: OpaquePointer?
            if sqlite3_prepare_v2(self._db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                if !(sqlite3_step(queryStatement) == SQLITE_DONE) {
                    goftamLog("error executing query: " + queryString)
                }
            } else {
                goftamLog("error preparing query string: " + queryString)
            }
            sqlite3_finalize(queryStatement)
        }
    }

}
