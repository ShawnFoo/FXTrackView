Pod::Spec.new do |spec|
  spec.name         = "FXDanmaku"
  spec.version      = "1.0.7"
  spec.summary      = "High-performance danmaku with GCD, reusable items and customize configurations."

  spec.homepage     = "https://github.com/ShawnFoo/FXDanmaku"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Shawn Foo" => "fu4904@gmail.com" }
  spec.platform     = :ios
  spec.ios.deployment_target = "7.0"

  spec.source       = { :git => "https://github.com/ShawnFoo/FXDanmaku.git", :tag => "v#{spec.version.to_s}" }
  spec.source_files  = "FXDanmaku/*.{h,m}"
  spec.framework  = "UIKit"
  spec.requires_arc = true
end
