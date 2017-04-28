Pod::Spec.new do |s|
s.name             = 'MGTwitterVideoUploader'
s.version          = '0.1.0'
s.summary          = 'Twitter video sharing made simple.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = 'Easily share videos to Twitter with the logged in accounts from iOS Settings.'

s.homepage         = 'https://github.com/marcosgriselli/MGTwitterVideoUploader'
# s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author         	 = 'Marcos Griselli'
s.source           = { :git => 'https://github.com/marcosgriselli/MGTwitterVideoUploader.git', :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/marcosgriselli'

s.ios.deployment_target = '8.0'

s.source_files = 'MGTwitterVideoUploader/Classes/**/*.{h,m,swift}'
end
