source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '15.0'

target 'WhereRU' do
  use_frameworks!

  pod 'AFNetworking', '~> 4.0'
  pod 'MBProgressHUD', '~> 1.2'
  pod 'UICKeyChainStore', '~> 2.1'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end

  # Fix deployment targets
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
