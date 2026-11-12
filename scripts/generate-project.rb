require 'xcodeproj'
require 'pathname'
root=File.expand_path('..',__dir__)
dir=File.join(root,'demo')
project=Xcodeproj::Project.new(File.join(dir,'CaresoftVoiceDemo.xcodeproj'))
package=project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package.relative_path='../packages/CaresoftVoice'
project.root_object.package_references << package
[
 ['CaresoftVoiceDemo','CaresoftVoiceDemo/DemoApp.swift',['CaresoftVoice','CaresoftVoiceUI']],
 ['ConsumerSwift','../Examples/ConsumerSwift/App.swift',['CaresoftVoice']],
 ['ConsumerObjC','../Examples/ConsumerObjC/main.m',['CaresoftVoice']]
].each do |name,source,products|
 target=project.new_target(:application,name,:ios,'15.1')
 sources = name == 'CaresoftVoiceDemo' ? Dir.glob(File.join(dir, 'CaresoftVoiceDemo/*.swift')).sort.map { |p| Pathname.new(p).relative_path_from(Pathname.new(dir)).to_s } : [source]
 if name == 'CaresoftVoiceDemo'
  assets = project.main_group.new_file('CaresoftVoiceDemo/Images.xcassets')
  target.resources_build_phase.add_file_reference(assets)
 end
 sources.each do |path|
  ref=project.main_group.new_file(path)
  target.source_build_phase.add_file_reference(ref)
 end
 products.each do |product|
  dependency=project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dependency.product_name=product
  target.package_product_dependencies << dependency
  file=project.new(Xcodeproj::Project::Object::PBXBuildFile)
  file.product_ref=dependency
  target.frameworks_build_phase.files << file
 end
 target.build_configurations.each do |config|
  settings=config.build_settings
  settings['ARCHS']='arm64'
  settings['PRODUCT_BUNDLE_IDENTIFIER']='com.example.'+name
  settings['SWIFT_VERSION']='5.0'
  settings['MARKETING_VERSION']='1.2.0'
  settings['CURRENT_PROJECT_VERSION']='3'
  settings['INFOPLIST_FILE']='Config/Info.plist'
  settings['TARGETED_DEVICE_FAMILY']='1,2'
  settings['CODE_SIGN_STYLE']='Automatic'
  settings['VOICE_PUSH_ENVIRONMENT']='sandbox'
  settings['APNS_ENTITLEMENT_ENVIRONMENT']='development'
  if name == 'CaresoftVoiceDemo'
   settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
   settings['VOICE_PUSH_ENVIRONMENT']='production' if config.name == 'Release'
   settings['PRODUCT_BUNDLE_IDENTIFIER']='com.example.CaresoftVoiceDemo'
   settings['CODE_SIGN_ENTITLEMENTS']='Config/Demo.entitlements'
  end
  settings['CLANG_ENABLE_MODULES']='YES'
  settings['LD_RUNPATH_SEARCH_PATHS']='$(inherited) @executable_path/Frameworks'
 end
 scheme=Xcodeproj::XCScheme.new
 scheme.add_build_target(target)
 scheme.set_launch_target(target)
 scheme.save_as(project.path,name,true)
end
require_relative 'add-demo-tests'
add_demo_tests(project)
project.save
puts project.path
