#
# Be sure to run `pod lib lint MJIM.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'MJAnalyse'
    s.version          = '0.1.3'
    s.summary          = '整理所有的第三方统计'

    s.homepage         = 'https://github.com/yangyu2010/MJAnalyse'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Yu Yang' => 'yangyu2010@aliyun.com' }
    s.source           = { :git => 'https://github.com/yangyu2010/MJAnalyse.git', :tag => "v-#{s.version}" }
    s.ios.deployment_target = '9.0'

    s.source_files = 'MJAnalyse/Classes/**/*'
    
    s.dependency 'ModuleCapability'
    s.dependency 'FBSDKCoreKit', '~> 4.36.0'
    s.dependency 'Adjust', '~> 4.15.0'
    
end
