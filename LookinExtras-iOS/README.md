# LookinExtras

Drop-in extra view attributes for [Lookin](https://lookin.work) iOS debugging.

LookinExtras adds Objective-C categories that implement the official
`lookin_customDebugInfos` extension point exposed by LookinServer SDK,
surfacing attributes the SDK does not capture by default.

## What's included (v0.1.0)

| Attribute | Type | Source |
|-----------|------|--------|
| `layer.maskedCorners` | string | `CALayer.maskedCorners` decoded into `TopLeft,TopRight,...` |

## Usage

Add to your app's `Podfile` (Debug only — release builds must NOT bundle this):

```ruby
pod 'LookinServer', :configurations => ['Debug']
pod 'LookinExtras',
    :git           => 'https://github.com/LeeLyonse/Lookin.git',
    :tag           => 'extras-v0.1.0',
    :configurations => ['Debug']
```

That's it. No `import` needed — the Objective-C runtime injects the category
automatically and LookinServer SDK picks up the extra attributes when it
collects the view hierarchy.

## Why a separate pod, not a SDK fork?

LookinServer ships with a public extension point `lookin_customDebugInfos`
specifically so users do not need to fork the SDK. LookinExtras lives on
top of that public API, which means:

- Zero ongoing maintenance vs. SDK upstream
- Zero modification to LookinServer source
- Drop-in for any project that already uses LookinServer

## License

MIT
