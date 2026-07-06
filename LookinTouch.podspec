Pod::Spec.new do |s|
  s.name         = 'LookinTouch'
  s.version      = '0.0.1'
  s.summary      = 'Debug-only UIKit touch and keyboard commands for Lookin console experiments.'
  s.description  = <<-DESC
    LookinTouch is a debug-only experiment that exposes no-argument UIView
    methods callable from the Lookin console. It creates synthetic UIKit
    touch events and inserts text into the current first responder to
    smoke-test app-local interaction automation.

    This pod uses private UIKit selectors and private IOKit symbols, and must
    never be included in Release builds.
  DESC
  s.homepage     = 'https://github.com/LeeLyonse/Lookin'
  s.license      = { :type => 'MIT' }
  s.author       = { 'LeeLyonse' => 'lilangzzztt@126.com' }
  s.source       = { :git => 'https://github.com/LeeLyonse/Lookin.git',
                     :tag => "touch-v#{s.version}" }
  s.platform     = :ios, '13.0'
  s.source_files = 'LookinTouch-iOS/Sources/**/*.{h,m}'
  s.requires_arc = true
  s.dependency   'LookinServer'
end
