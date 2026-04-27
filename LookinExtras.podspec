Pod::Spec.new do |s|
  s.name         = 'LookinExtras'
  s.version      = '0.1.1'
  s.summary      = 'Drop-in extra view attributes that LookinServer SDK does not capture by default.'
  s.description  = <<-DESC
    LookinExtras adds Objective-C categories on UIView/CALayer that implement
    the official `lookin_customDebugInfos` extension point exposed by LookinServer SDK.

    It surfaces attributes that LookinServer 1.2.x does not capture out of the box,
    such as `layer.maskedCorners`, `view.directionalLayoutMargins`,
    `view.semanticContentAttribute`, etc.

    Drop the pod into any iOS app that already integrates `LookinServer` (Debug-only)
    and the extra attributes will appear in the Lookin macOS client automatically.
    No code import required — Objective-C runtime takes care of category injection.
  DESC
  s.homepage     = 'https://github.com/LeeLyonse/Lookin'
  s.license      = { :type => 'MIT' }
  s.author       = { 'LeeLyonse' => 'lilangzzztt@126.com' }
  s.source       = { :git => 'https://github.com/LeeLyonse/Lookin.git',
                     :tag => "extras-v#{s.version}" }
  s.platform     = :ios, '13.0'
  s.source_files = 'LookinExtras-iOS/Sources/**/*.{h,m}'
  s.requires_arc = true
  s.dependency   'LookinServer'
end
