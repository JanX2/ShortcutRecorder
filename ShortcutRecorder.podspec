Pod::Spec.new do |s|
  s.name         = 'ShortcutRecorder'
  s.homepage = "https://github.com/Kentzo/ShortcutRecorder"
  s.summary = "The only user interface control to record shortcuts."
  s.version      = '2.13'
  s.source       = { :git => 'git://github.com/Kentzo/ShortcutRecorder.git',
                     :branch => 'master' }
  s.author       = { 'Ilya Kulakov' => 'kulakov.ilya@gmail.com' }
  s.source_files = 'Library/*.{h,m}'
  s.frameworks   = 'Carbon', 'Cocoa'
  s.resource_bundles    = { "ShortcutRecorder" => ['Resources/*.lproj', 'Resources/*.png'] }
  s.requires_arc = true
  s.prefix_header_file = 'Library/Prefix.pch'
  s.platform     = :osx, "10.6"

  s.subspec 'PTHotKey' do |hotkey|
    hotkey.source_files = 'PTHotKey/*.{h,m}'
    hotkey.requires_arc = false
  end
end
