# goftam

Work in progress transliterating input method for macOS. Currently Persian is
supported, but it is relatively straightforward to add other languages and
scripts.

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

TODO
- add a dictionary pass to prioritize real words
- use Artifical Intelligence Machine Learning Big Data technology to improve
  candidate suggestions
- add a timeout for long searches
- punctuation map
- build string
- debug levels
