Gem::Specification.new do |s|
  s.name        = "multipart_body"
  s.version     = "0.3.2"
  s.author      = ""
  s.email       = ""
  s.homepage    = "http://github.com/Roostify/multipart_body"
  s.description = "A ruby library to create multipart bodies. Derived from gem of same name by Steve Smith, gems@dynedge.co.uk."
  s.summary     = "MultipartBody allows you to create consistant multipart bodies"

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false

  s.require_path = 'lib'
  s.files = %w(readme.md) + Dir.glob("lib/**/*")
  s.add_development_dependency "minitest"
end
