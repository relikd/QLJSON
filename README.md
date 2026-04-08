[![macOS 10.15+](https://img.shields.io/badge/macOS-10.15+-888)](#)
[![Current release](https://img.shields.io/github/release/relikd/QLJSON)](https://github.com/relikd/QLJSON/releases/latest)
[![All downloads](https://img.shields.io/github/downloads/relikd/QLJSON/total)](https://github.com/relikd/QLJSON/releases)

![icon](resources/icon.png)


QLJSON
======

QuickLook plugin for `.json` files.

![screenshot](resources/screenshot.png)

I have been using [QuicklookJSON][1] until recently but it has no support for macOS 15.
I copied some parts of [QuickJSON][2] but did through away almost everything.
The remaining code was heavily refactored.


Installation
------------

Requires macOS Catalina (10.15) or higher.

```sh
brew install --cask relikd/tap/qljson
xattr -d com.apple.quarantine /Applications/QLJSON.app
```

or download from [releases](https://github.com/relikd/QLJSON/releases/latest).


Features
--------

- No dependencies
- Small app size (2 MB)
- Easy to review (lines of code: 40 Swift + 100 JS)
- Dark Mode
- Foldable structures
- Customizable html output

### How to customize CSS / JS

1. Right click on the app and select "Show Package Contents"
2. Go to `PlugIns` and repeat "Show Package Contents" on the Preview extension.
3. Copy `Contents/Resources/style.css` (or `script.js`)
4. Open `~/Library/Containers/de.relikd.QLJSON.Preview/Data/Documents/`
5. Paste the previous file and modify it to your liking (e.g. change text colors)


[1]: http://www.sagtau.com/quicklookjson.html
[2]: https://github.com/johan/QuickJSON
