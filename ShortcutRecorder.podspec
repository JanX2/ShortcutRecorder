Pod::Spec.new do |s|
  s.cocoapods_version = '>= 1.8'
  s.name = 'ShortcutRecorder'
  s.version = '3.0'
  s.summary = 'The best control to record shortcuts on macOS'
  s.homepage = 'https://github.com/Kentzo/ShortcutRecorder'
  s.license = { :type => 'CC BY 4.0', :file => 'LICENSE.txt' }
  s.author = { 'Ilya Kulakov' => 'kulakov.ilya@gmail.com' }

  s.source = { :git => 'https://github.com/Kentzo/ShortcutRecorder.git', :tag => s.version }

  s.platform = :osx
  s.osx.deployment_target = "10.11"
  s.frameworks = 'Carbon', 'Cocoa'

  s.source_files = 'Library/*.{h,m}'
  s.resources = ['Resources/*.lproj', 'Resources/Images.xcassets']
  s.requires_arc = true
  s.info_plist = {
    'CFBundleIdentifier' => 'com.kulakov.ShortcutRecorder'
  }
end
