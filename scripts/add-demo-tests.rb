# Shared by project generation and used to keep the checked-in demo project in sync.
def add_demo_tests(project)
  app = project.targets.find { |t| t.name == 'CaresoftVoiceDemo' }
  target = project.new_target(:unit_test_bundle, 'CaresoftVoiceDemoTests', :ios, '15.1')
  target.add_dependency(app)
  target.source_build_phase.add_file_reference(project.main_group.new_file('Tests/KeychainTests.swift'))
  dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dependency.product_name = 'CaresoftVoice'
  target.package_product_dependencies << dependency
  file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  file.product_ref = dependency
  target.frameworks_build_phase.files << file
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'PRODUCT_BUNDLE_IDENTIFIER' => 'com.example.CaresoftVoiceDemoTests',
      'SWIFT_VERSION' => '5.0', 'GENERATE_INFOPLIST_FILE' => 'YES',
      'TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/CaresoftVoiceDemo.app/CaresoftVoiceDemo',
      'BUNDLE_LOADER' => '$(TEST_HOST)',
      'CODE_SIGN_STYLE' => 'Automatic'
    })
  end
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(app)
  scheme.add_build_target(target, false)
  scheme.add_test_target(target)
  scheme.set_launch_target(app)
  scheme.save_as(project.path, 'CaresoftVoiceDemo', true)
end
