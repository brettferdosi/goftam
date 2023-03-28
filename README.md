<img src="https://github.com/brettferdosi/goftam/raw/doc/icon.png" width="150px">

# Goftam

Goftam is a transliterating input method for macOS. It allows you to type in different scripts with your usual keyboard layout, which may be much faster than learning additional keyboard layouts.

<img src="https://github.com/brettferdosi/goftam/raw/doc/demo.gif" width="650px">

Currently, only Persian is supported, but it is straightforward to add other languages and scripts. Goftam has been tested on macOS 10.15 Catalina but may also work on other versions.

## Installing and enabling Goftam

`goftam.app` must be placed in `/Library/Input Methods` to install it for all users or `~/Library/Input Methods` to install it for a particular user.

**Install option 1: homebrew**

Run `brew install --cask --no-quarantine brettferdosi/tap/goftam`. `goftam.app` will be
installed in `~/Library/Input Methods`.

**Install option 2: run the installer (easiest for non-technical users)**

Download the [most recent installer](https://github.com/brettferdosi/goftam/releases/latest/download/GoftamInstaller.pkg) (`GoftamInstaller.pkg`) from the [releases page](https://github.com/brettferdosi/goftam/releases).
To run the installer, control-click its icon, click *Open*, then click *Open* again.
See the [Apple support page](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unidentified-developer-mh40616/mac) if the process for running apps from unidentified developers has changed.
It will install `goftam.app` in `/Library/Input Methods`.
If there is already a version of `goftam.app` on your system, the installer will detect and overwrite it.

**Install option 3: build from source**

Clone this git repository and run `make` in it.
`goftam.app` will be placed into `build/Build/Products/Release`.

**Enabling Goftam**

Open System Settings > Keyboard then click the Edit button next to Input Sources followed by the + button to add input sources. Add Goftam inputs, which are categorized by their target languages (e.g. Goftam Persian is categorized as a Persian input method), as desired. You can then use Goftam inputs by selecting them from the input menu bar button or using your configured shortcut key to cycle through input sources.

<img src="https://github.com/brettferdosi/goftam/raw/doc/menubar.png" width="500px">

If selecting a Goftam input method does not work immediately after installing it, you may need to log out then back in.

**Uninstalling Goftam**

To remove Goftam from your system completely, delete `goftam.app` from wherever you installed it and also delete the directory `~/Library/Application Support/in.gutste.inputmethod.goftam` for all users that had Goftam enabled.

## Using Goftam

With a Goftam input enabled, the input keyboard layout is set to the most recently used ASCII-capable layout (in many cases, this will be the keyboard layout of your computer's physical keyboard that you are used to). All inputted text is transliterated into the target language and script. Typing starts a transliteration composition, and transliteration candidates are displayed in a window underneath the composition. When you are ready to commit a composition, you can choose a candidate from the window using the arrow and enter keys, the mouse, or number keys corresponding to the numbers next to the candidates. The escape key cancels the in-progress composition.

Typing a punctuation mark or symbol commits the in-progress composition by selecting the currently highlighted candidate, and the (potentially translated) symbol is then inserted. Typing a numeric digit while there is no composition in progress inserts a translated version of the digit.

Typing `shift-space` will insert a [zero-width non-joiner character](https://en.wikipedia.org/wiki/Zero-width_non-joiner), which is useful for various scripts and languages.

To switch between input modes quickly, you can use the *Select the previous input source* system keyboard shortcut. This is `control-space` by default.

## Goftam Persian

Goftam Persian works by applying transliteration rules in priority order to generate candidates for a given input string. Of those candidates, ones that have been previously selected by the user or that are determined to be valid Persian words are moved to the top of the list.

Because transliteration rules are applied in priority order to generate candidates, you can target specific rules to make a desired candidate appear closer to the top of the list. For example, a rule mapping character "a" to an empty string ("") is applied before one that matches it to alef ("ا"), but the two-character sequence "aa" maps to alef before the empty string. With no saved user history, the string "baradar" yields بردار before برادر, but "baraadar" yields برادر before بردار.

To render prefixes and suffixes, you can type `shift-space` to insert a zero-width non-joiner. Some transliteration rules have been added to enable shortcuts for certain suffixes. All of the transliteration rules can be found in `Sources/PersianGoftamTransliterator.swift`

## Adding a language

You can add a lanaguage/script to Goftam by taking the following steps:

1. Create a class that implements the `GoftamTransliterator` protocol. You can optionally use transliteration rules and the `GoftamTransliterationEngine` class to generate candidates and the `GoftamWordStore` class to store a list of recognized words and user selection history (note that to test your work, you should delete Goftam's Application Support directory after modifying the SQLite database underlying `GoftamWordStore`). See `PersianGoftamTransliterator` for an example.

2. Create an input mode for the language by adding entries to `tsInputModeListKey` and `tsVisibleInputModeOrderedArrayKey` in `ComponentInputModeDict` in `Resources/Info.plist`.

3. Add a mapping to the `transliterators` Dictionary in `Sources/AppDelegate.swift` for your new transliterator and input method.
