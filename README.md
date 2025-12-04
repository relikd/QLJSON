![macOS 10.15+](https://img.shields.io/badge/macOS-10.15+-888)
[![Current release](https://img.shields.io/github/release/relikd/QLJSON)](https://github.com/relikd/QLJSON/releases)
[![GitHub license](https://img.shields.io/github/license/relikd/QLJSON)](LICENSE)


QLJSON
======

Just a simple tool for QuickLook-ing `.json` files.

![screenshot](screenshot.png)

I have been using [QuicklookJSON][1] until recently but it has no support for macOS 15.
I copied some parts of [QuickJSON][2] but did through away almost everything.
The remaining code was heavily refactored.


## Features

- Dark Mode
- Foldable structure
- Customizable CSS / JS


### How to customize CSS / JS

1. Right click on the app and select "Show Package Contents"
2. Go to `PlugIns` and repeat "Show Package Contents" on the Preview extension.
3. Copy `Contents/Resources/style.css` (or `script.js`)
4. Open `~/Library/Containers/de.relikd.QLJSON.Preview/Data/Documents/`
5. Paste the previous file and modify it to your liking (e.g. change text colors)


[1]: http://www.sagtau.com/quicklookjson.html
[2]: https://github.com/johan/QuickJSON
