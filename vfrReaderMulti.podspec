Pod::Spec.new do |s|
  s.name         = "vfrReaderMulti"
  s.version      = "0.1.1"
  s.summary      =  "vfrReader with multi pdf"
  s.license      = "MIT"
  s.homepage = "http://www.creacree.com/"
  s.author       = { "nealx" => "nealxue.sh@gmail.com" }
  s.source = { :git => "https://github.com/nealx/Reader.git", :tag => "#{s.version}" }
  s.platform     = :ios
  s.ios.deployment_target = "6.0"
  s.source_files = "Sources/**/*.{h,m}"
  s.resources = "Graphics/Reader-*.png"
  s.frameworks = "UIKit", "Foundation", "CoreGraphics", "QuartzCore", "ImageIO", "MessageUI"
  s.requires_arc = true
  s.dependency "AFNetworking", "~> 3.0"
end
