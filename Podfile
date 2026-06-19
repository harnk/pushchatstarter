source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '15.0'

target 'WhereRU' do
  use_frameworks!

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

  # === Privacy Manifest Fix for Old Pods ===
  puts "\n🔧 Adding Privacy Manifests for old frameworks..."

  installer.pods_project.targets.each do |target|
    if ['UICKeyChainStore'].include?(target.name)
      framework_path = "Pods/Target Support Files/#{target.name}"
      if Dir.exist?(framework_path)
        privacy_file = "#{framework_path}/PrivacyInfo.xcprivacy"
        privacy_content = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>NSPrivacyTracking</key>
              <false/>
              <key>NSPrivacyCollectedDataTypes</key>
              <array/>
          </dict>
          </plist>
        XML

        File.write(privacy_file, privacy_content)
        puts "✅ Added PrivacyInfo.xcprivacy to #{target.name}"
      end
    end
  end
end
