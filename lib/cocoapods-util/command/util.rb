require 'cocoapods-util/package/package'
require 'cocoapods-util/xcframework/xcframework'
require 'cocoapods-util/libsource/source'

require 'cocoapods-util/cocoapods-extend/extend'

module Pod
  class Command
    class Util < Command
      self.summary = '一个CocoaPods插件，包括打包二进制（library/framework/xcframework）、framework生成xcframework、二进制link源码等功能。'
      self.description = <<-DESC
      一个CocoaPods常用插件功能的集合，致力于解决日常开发中遇到的一些问题。目前支持打包二进制（library/framework/xcframework/支持swift）、使用framework生成xcframework、二进制源码链接、推送私有库跳过验证`pod util repo push`，后续将支持生成编译产物加快编译速度等功能。
      DESC
      self.command == 'util'
      self.abstract_command = true
      def initialize(argv)
        super
      end

      def validate!
        super
      end

      def run
      end
    end
  end
end