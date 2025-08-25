#!/usr/bin/env ruby
require 'xcodeproj'

# Path to your Xcode project
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Runner' }

# Add ARKit framework if not already added
arkit_framework = project.frameworks_group.files.find { |f| f.display_name == 'ARKit.framework' }
if !arkit_framework
  arkit_framework = project.frameworks_group.new_file('System/Library/Frameworks/ARKit.framework', :sdk_root)
  target.frameworks_build_phases.add_file_reference(arkit_framework)
end

# Update build settings
target.build_configurations.each do |config|
  # Set iOS deployment target
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  
  # Enable modules and set Swift version
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  
  # Disable Bitcode
  config.build_settings['ENABLE_BITCODE'] = 'NO'
  
  # Add framework search paths
  framework_search_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || ['$(inherited)']
  framework_search_paths |= [
    '$(PROJECT_DIR)/Flutter',
    '$(PROJECT_DIR)/../.symlinks/plugins/arkit_plugin/ios/ARKitPlugin'
  ]
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = framework_search_paths
  
  # Add linker flags
  other_ldflags = config.build_settings['OTHER_LDFLAGS'] || ['$(inherited)']
  other_ldflags |= [
    '-ObjC',
    '-lc++',
    '-framework',
    'ARKit'
  ]
  config.build_settings['OTHER_LDFLAGS'] = other_ldflags
  
  # Ensure proper runpath
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= [
    '$(inherited)',
    '@executable_path/Frameworks'
  ]
end

# Save the project
project.save

puts "ARKit configuration completed successfully!"
