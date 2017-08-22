#
# Be sure to run `pod lib lint Pbind.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Pbind'
  s.version          = '1.3.8'
  s.summary          = 'A tiny MVVM framework that use Plist to build UIs and Databindings.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Pbind, a data binder with Plist, which help you to achieve "Less code, More efficient".
                       DESC

  s.homepage         = 'https://github.com/wequick/Pbind'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'galenlin' => 'oolgloo.2012@gmail.com' }
  s.source           = { :git => 'https://github.com/wequick/Pbind.git', :tag => s.version.to_s }
  s.social_media_url = 'https://weibo.com/galenlin'

  s.ios.deployment_target = '7.0'

  s.source_files = 'Pbind/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Pbind' => ['Pbind/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
