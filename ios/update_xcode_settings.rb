#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Runner' }

# Update build settings for all configurations
target.build_configurations.each do |config|
  # Set iOS deployment target
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  
  # Enable modules and set Swift version
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  
  # Disable Bitcode
  config.build_settings['ENABLE_BITCODE'] = 'NO'
  
  # Set framework search paths
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = [
    '$(inherited)',
    '$(PROJECT_DIR)/Flutter',
    '$(PROJECT_DIR)/../.symlinks/plugins/arkit_plugin/ios/ARKitPlugin',
    '$(SDKROOT)/Developer/Library/Frameworks',
    '$(inherited)'
  ]
  
  # Set header search paths
  config.build_settings['HEADER_SEARCH_PATHS'] = [
    '$(inherited)',
    '${PODS_ROOT}/Headers/Public',
    '${PODS_ROOT}/Headers/Public/arkit_plugin'
  ]
  
  # Set Swift include paths
  config.build_settings['SWIFT_INCLUDE_PATHS'] = '$(inherited) ${PODS_ROOT}/arkit_plugin/ios/Classes'
  
  # Set other linker flags
  config.build_settings['OTHER_LDFLAGS'] = [
    '$(inherited)',
    '-ObjC',
    '-lc++',
    '-framework',
    'ARKit'
  ]
  
  # Set runpath search paths
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks'
  ]
  
  # Set Swift optimization level for debug builds
  if config.name == 'Debug'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  end
end

# Save the project
project.save

puts "Xcode project settings updated successfully!"
