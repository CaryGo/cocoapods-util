# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-util/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-util'
  spec.version       = CocoapodsUtil::VERSION
  spec.authors       = ['guojiashuang']
  spec.email         = ['guojiashuang@live.com']
  spec.description   = %q{cocoapods-util是一个cocoapods插件集合，包括package、生成xcframework等功能。}
  spec.summary       = %q{一个常用插件功能的集合，目前支持打包、生成xcframework，后续将支持二进制源码链接、生成编译产物加快编译速度等功能。}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-util'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
