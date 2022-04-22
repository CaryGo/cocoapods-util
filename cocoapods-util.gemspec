# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-util/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-util'
  spec.version       = CocoapodsUtil::VERSION
  spec.authors       = ['guojiashuang']
  spec.email         = ['guojiashuang@live.com']
  spec.description   = %q{cocoapods-util是一个常用插件功能的集合，致力于解决日常开发中遇到的一些问题。目前支持打包二进制（library/framework/xcframework/支持swift）、使用framework生成xcframework、二进制link源码（不切换源码，直接用二进制调试）等功能。}
  spec.summary       = %q{一个常用插件功能的集合，致力于解决日常开发中遇到的一些问题。目前支持打包二进制（library/framework/xcframework/支持swift）、使用framework生成xcframework、二进制link源码（不切换源码，直接用二进制调试）等功能。}
  spec.homepage      = 'https://github.com/CaryGo/cocoapods-util'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
