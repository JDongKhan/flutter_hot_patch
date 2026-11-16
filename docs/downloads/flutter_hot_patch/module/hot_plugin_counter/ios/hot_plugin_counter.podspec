Pod::Spec.new do |s|
  s.name             = 'hot_plugin_counter'
  s.version          = '1.0.0'
  s.summary          = 'Hot patch demo plugin B (counter).'
  s.description      = 'MethodChannel demo plugin: native counter.'
  s.homepage         = 'https://example.com/hot_patch'
  s.license          = { :type => 'MIT' }
  s.author           = { 'hot_patch' => 'hot_patch@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
