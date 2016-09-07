#
# Be sure to run `pod lib lint Less.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Less'
  s.version          = '0.1.0'
  s.summary          = 'A tiny MVVM framework that use Plist to build UIs and Databindings.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Less code, more efficient. Less is a tiny MVVM framework that use Plist to build UIs and Databindings.
                       DESC

  s.homepage         = 'https://github.com/wequick/Less'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'galenlin' => 'oolgloo.2012@gmail.com' }
  s.source           = { :git => 'https://github.com/wequick/Less.git', :tag => s.version.to_s }
  s.social_media_url = 'https://weibo.com/galenlin'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Less/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Less' => ['Less/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
