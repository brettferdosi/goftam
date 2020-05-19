# goftam

Work in progress transliterating input method for macOS. Currently Persian is
supported, but it is relatively straightforward to add other languages and
scripts.

## how to use it

The default input keyboard layout is set to the most recently used
ASCII-capable keyboard layout. Shift-space inserts a ZWNJ. Command-shift-space
bypasses transliteration.

Advanced usage: making a selection with numbers adds a space afterwards,
whereas typing a symbol while a selection is highlighted makes the selection
and inserts the symbol. For efficiency, do the following. If the word is in the
middle of a sentence (i.e., its translation will be followed by a space), then
if the first suggestion is the desired transliteration you can simply hit
space; otherwise select with the number keys. If the word needs to be followed
by a symbol, like a period or a ZWNJ, highlight the selection using the arrow
keys then enter the symbol; or make the selection with number keys, backspace,
and enter the symbol.

If you want to write bypassed and non-bypassed text in the same line, add a
space after your bypassed text before going back into non-bypass mode

## how to install it

for uninstall, remove the app and also database in ~/Library/Application Support/blah 

## how it works

## adding a language
- add a class that implements the GoftamTransliterator protocol, optionally using (1) transliteration rules and the GoftamTransliterationEngine class and (2) a sqlite dictionary/user history table using the GoftamWordStore class. See PersianGoftamTransliterator for an example.
- create an input mode for the language by adding entries to tsInputModeListKey and tsVisibleInputModeOrderedArrayKey in ComponentInputModeDict in Info.plist
- add a mapping to the transliterators dictionary in AppDelegate.swift for your new transliterator and input method
- note that when you modify the database you should delete your application support directory

TODO
- add a timeout for long searches
- punctuation map
- packaging (homebrew?)
- main icon, dark mode menu bar icons
- fix the readme
