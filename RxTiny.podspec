Pod::Spec.new do |s|
  s.name         = "RxTiny"
  s.version      = "0.1.8"
  s.summary      = "A short description of RxTiny."

  s.description  = <<-DESC
                   A longer description of RxTiny in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/jumperb/RxTiny"

  s.license      = "Copyright"
  
  s.author       = { "jumperb" => "zhangchutian_05@163.com" }

  s.source       = { :git => "https://github.com/jumperb/RxTiny.git", :tag => s.version.to_s}

  s.requires_arc = true
  
  s.ios.deployment_target = '8.0'
  s.dependency 'Hodor'
  s.ios.source_files = 'Classes/*'  
end
