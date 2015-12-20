Pod::Spec.new do |s|
  s.name             = "Particle-SDK"
  s.version          = "0.1.4"
  s.summary          = "Swift port of SparkSDK for iOS and Mac OS X"
  s.homepage         = "https://github.com/nielubowicz/Particle-SDK"
  s.license          = 'MIT'
  s.author           = { "Chris Nielubowicz" => "nielubowicz@gmail.com" }
  s.source           = { :git => "https://github.com/nielubowicz/Particle-SDK.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true

  s.source_files = 'Source/**/*'
  s.dependency 'Alamofire'

end
