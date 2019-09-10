@version = "1.0.1"

Pod::Spec.new do |s|
  s.name         	= 'VXRecognitionViewController'
  s.version      	= @version
  s.summary     	= 'Integration image classification into your app.'
  s.homepage 	   	= 'https://github.com/swiftmanagementag/VXRecognitionViewController'
  s.license			= { :type => 'MIT', :file => 'LICENSE' }
  s.author       	= { 'Graham Lancashire' => 'lancashire@swift.ch' }
  s.source       	= { :git => 'https://github.com/swiftmanagementag/VXRecognitionViewController.git', :tag => s.version.to_s }
  s.platform     	= :ios, '12.0'
  s.source_files 	= 'VXRecognitionViewController/**/*.swift'
  #s.frameworks		= 'StoreKit', 'CoreImage'
  #s.resources 		= 'VXPromotionViewController/**/*.{bundle,xib,png,lproj}'
  s.resource_bundles = {
    'VXRecognitionViewController' => ['VXRecognitionViewController/**/*.{xcassets,xib,png,lproj}']
  }
  s.requires_arc 	= true
end
