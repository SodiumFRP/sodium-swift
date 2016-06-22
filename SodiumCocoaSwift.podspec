Pod::Spec.new do |s|

  s.name         = "SodiumCocoaSwift"
  s.version      = "0.2.4"
  s.summary      = "Sodium library for Swift Cocoa controls."
  s.description  = <<-DESC
    Sodium FRP library for Cocoa controls.
    Swift 2.2 (XCode 7.3.1)
  DESC

  s.homepage     = "https://github.com/SodiumFRP/sodium-swift.git"
  s.license      = { :type => "MIT", :file => "COPYING" }
  s.authors      = { "Stephen Blackheath", "Anthony Jones", "Andrew Bradnan" }
  s.social_media_url   = "http://twitter.com/NullPlague"
  
  # only because we are using frameworks
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/SodiumFRP/sodium-swift.git", :tag => s.version }
  s.source_files  = "SodiumCocoa/**/*.{swift}"
end
