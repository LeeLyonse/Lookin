Pod::Spec.new do |s|
  s.name         = 'LookinDump'
  s.version      = '0.1.0'
  s.summary      = 'Debug-only Lookin console property-chain dumper.'
  s.description  = <<-DESC
    LookinDump adds the `lkdump__` debug selector bridge for printing property
    chains from the Lookin console. It can read Swift stored properties via
    reflection and Objective-C no-argument getters, including common scalar
    return types.

    This pod is intended for Debug builds only and must never be included in
    Release builds.
  DESC
  s.homepage     = 'https://github.com/LeeLyonse/Lookin'
  s.license      = { :type => 'MIT' }
  s.author       = { 'LeeLyonse' => 'lilangzzztt@126.com' }
  s.source       = { :git => 'https://github.com/LeeLyonse/Lookin.git',
                     :tag => "dump-v#{s.version}" }
  s.platform     = :ios, '13.0'
  s.source_files = 'LookinDump-iOS/Sources/**/*.{h,m,swift}'
  s.requires_arc = true
  s.swift_version = '5.0'
  s.dependency   'LookinServer'
end
