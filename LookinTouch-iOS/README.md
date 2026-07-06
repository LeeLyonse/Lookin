# LookinTouch

Debug-only UIKit touch event experiment for Lookin console.

## Usage

Add to a debug app target only:

```ruby
pod 'LookinServer', :configurations => ['Debug']
pod 'LookinTouch',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'touch-v0.0.1',
    :configurations => ['Debug']
```

Select a `UIView` in Lookin, then run:

```text
lktouch__tapCenter
lktouch__tapVisibleCenter
lktouch__swipeUp
lktouch__swipeDown
lktouch__swipeLeft
lktouch__swipeRight
lktype__hello
lktype_hex__E4BDA0E5A5BD
lktype__pasteboard
lkdelete__3
lkreturn
```

`lktouch__tapCenter` taps the selected view's bounds center.
`lktouch__tapVisibleCenter` intersects the selected view with its window bounds
first, then taps the visible rect center.
Swipe commands start and end inside the selected view's visible rect.
Keyboard commands type into the current first responder. Use `lktype__...` for
simple selector-safe text, `lktype_hex__...` for UTF-8 hex text, and
`lktype__pasteboard` for longer strings.

This is an experiment. It uses private UIKit selectors and private IOKit symbols
for `UITouch`/`UIEvent` backing data, and must never ship in Release builds.
