# LookinExtras

Drop-in extra view attributes for [Lookin](https://lookin.work) iOS debugging.

LookinExtras adds Objective-C categories that implement the official
`lookin_customDebugInfos` extension point exposed by LookinServer SDK,
surfacing attributes the SDK does not capture by default.

## What's included (v0.1.3)

| Attribute | Type | Source |
|-----------|------|--------|
| `layer.maskedCorners` | string | `CALayer.maskedCorners` decoded into `TopLeft,TopRight,...` |
| `attributedText` | json | `UILabel`, `UITextView`, and `UITextField` attributed text as readable text plus `NSAttributedString.description` |
| `attributedPlaceholder` | json | `UITextField.attributedPlaceholder` as readable text plus `NSAttributedString.description` |
| `attributedTitle.*` | json | `UIButton` normal/highlighted/selected/disabled attributed titles as readable text plus `NSAttributedString.description` |
| `lkdump__...` | string | Runtime property-chain dumper for the Lookin console |

## Usage

Add to your app's `Podfile` (Debug only — release builds must NOT bundle this):

```ruby
pod 'LookinServer', :configurations => ['Debug']
pod 'LookinExtras',
    :git           => 'https://github.com/LeeLyonse/Lookin.git',
    :tag           => 'extras-v0.1.3',
    :configurations => ['Debug']
```

That's it. No `import` needed — the Objective-C runtime injects the category
automatically and LookinServer SDK picks up the extra attributes when it
collects the view hierarchy.

## Console property-chain dump

Select a view in Lookin, then print a property chain in the Lookin console:

```text
lkdump__nextResponder__viewModel__currentOptionsForMap
lkdump__frame
```

The `lkdump__` bridge runs inside the debug iOS app. It can read Swift stored
properties via reflection and Objective-C no-argument getters, including common
scalar return types. Swift *computed* properties that are not exposed to the
Objective-C runtime cannot be resolved and print `<nil>`.

> **Caveat:** each path component is invoked as a zero-argument method, so a
> component that names a value-returning method with side effects (e.g.
> `becomeFirstResponder`) will actually execute it. Only dump pure getters and
> stored properties. Do not include this pod in Release builds.

## Why a separate pod, not a SDK fork?

LookinServer ships with a public extension point `lookin_customDebugInfos`
specifically so users do not need to fork the SDK. LookinExtras lives on
top of that public API, which means:

- Zero ongoing maintenance vs. SDK upstream
- Zero modification to LookinServer source
- Drop-in for any project that already uses LookinServer

## License

MIT
