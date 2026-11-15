#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint applovin_max.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.authors          = 'AppLovin Corporation'
  s.name             = 'applovin_max'
  s.version          = '4.6.4'
  s.summary          = 'AppLovin MAX Flutter Plugin'
  s.description      = <<-DESC
AppLovin MAX Flutter Plugin
DESC
  s.homepage         = 'https://www.applovin.com/'
  s.license          = { :file => '../LICENSE' }
  s.source           = { :path => '.' }
  s.source_files     = 'applovin_max/Sources/applovin_max/**/*.{h,m}'
  s.public_header_files = 'applovin_max/Sources/applovin_max/include/**/*.h'
  s.platform = :ios, '12.0'
  s.static_framework = true
  s.dependency 'Flutter'

  # AppLovinSDK is published as a Swift package only; new versions are not on CocoaPods trunk. This plugin version
  # gets it through Swift Package Manager (ios/applovin_max/Package.swift), so it can't be installed with CocoaPods.
  # With Swift Package Manager on, Flutter uses Package.swift and never reads this podspec (plugins without a
  # Package.swift still come from CocoaPods), so this only runs when Swift Package Manager is off.
  raise "applovin_max #{s.version} requires Swift Package Manager (on by default from Flutter 3.44; otherwise run " \
        "`flutter config --enable-swift-package-manager`). Plugins that only support CocoaPods keep working " \
        "alongside it. To keep Swift Package Manager off, stay on an earlier applovin_max release."
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
