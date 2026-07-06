# LookinDump

Debug-only Lookin console property-chain dumper.

`LookinDump` is separate from `LookinExtras`: use it when the project only needs
console-driven property inspection and does not want extra automatic UI
attributes.

## Usage

Add to your app's `Podfile` (Debug only):

```ruby
pod 'LookinServer', :configurations => ['Debug']
pod 'LookinDump',
    :git           => 'https://github.com/LeeLyonse/Lookin.git',
    :tag           => 'dump-v0.1.0',
    :configurations => ['Debug']
```

Select a view in Lookin, then print a property chain in the Lookin console:

```text
lkdump__nextResponder__viewModel__currentOptionsForMap
lkdump__frame
```

The `lkdump__` bridge runs inside the debug iOS app. It can read Swift stored
properties via reflection and Objective-C no-argument getters, including common
scalar return types. Swift computed properties that are not exposed to the
Objective-C runtime cannot be resolved and print `<nil>`.

Each path component is invoked as a zero-argument method, so a component that
names a value-returning method with side effects, such as `becomeFirstResponder`,
will actually execute it. Only dump pure getters and stored properties.

Do not include this pod in Release builds.
