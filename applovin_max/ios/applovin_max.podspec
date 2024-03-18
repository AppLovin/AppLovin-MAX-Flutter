#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint applovin_max.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.authors          = 'AppLovin Corporation'
  s.name             = 'applovin_max'
  s.version          = '3.8.1'
  s.summary          = 'AppLovin MAX Flutter Plugin'
  s.description      = <<-DESC
AppLovin MAX Flutter Plugin
DESC
  s.homepage         = 'https://www.applovin.com/'
  s.license          = { :file => '../LICENSE' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.platform = :ios, '11.0'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'AppLovinSDK', '12.3.1'
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
