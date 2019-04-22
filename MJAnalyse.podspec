#
# Be sure to run `pod lib lint MJIM.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'MJAnalyse'
    s.version          = '0.2.9'
    s.summary          = '集成Facebook, Firebase等第三方统计'

    s.homepage         = 'https://github.com/yangyu2010/MJAnalyse'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Yu Yang' => 'yangyu2010@aliyun.com' }
    s.source           = { :git => 'https://github.com/yangyu2010/MJAnalyse.git', :tag => "v-#{s.version}" }
    s.ios.deployment_target = '9.0'

    s.subspec 'Analyse' do |ss|
        ss.source_files = 'MJAnalyse/Classes/MJAnalyse.{h,m}'
        ss.dependency 'ModuleCapability'
        ss.dependency 'FBSDKCoreKit'
        ss.dependency 'MJKeyManager'
    end
    
    s.subspec 'ViewController' do |ss|
        ss.source_files = 'MJAnalyse/Classes/UIViewController+Analyse.{h,m}'
        ss.dependency 'MJAnalyse/Analyse'
    end
    
end
