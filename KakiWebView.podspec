Pod::Spec.new do |s|
  s.name         = "KakiWebView"
  s.version      = "0.0.1"
  s.summary      = "Simple && Scalable UIWebview Framework"

  s.homepage     = "http://blog.makeex.com/2017/04/06/thinking-in-fe-how-to-enhance-the-uiwebview/"
  s.license      = "MIT"
  s.author       = { "makee" => "wengyang56@163.com" }
  s.source       = { :git => "git@github.com:prinsun/KakiWebView.git", :tag => "#{s.version}" }

  s.source_files  = "KakiWebView/Classes/**/*.{h,m,mm,c,cpp}"

  s.frameworks = "UIKit", "JavaScriptCore"
end
