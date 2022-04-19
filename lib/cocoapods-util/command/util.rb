require 'cocoapods-util/package/package'
require 'cocoapods-util/xcframework/xcframework'
require 'cocoapods-util/libsource/source'

require 'cocoapods-util/test/test'

module Pod
  class Command
    class Util < Command
      self.summary = '一个CocoaPods插件，包括package、framework生成xcframework、二进制link源码等功能。使用`pod util --help`查看支持功能'
      self.description = <<-DESC
      一个常用插件功能的集合，目前支持打包、生成xcframework、二进制源码链接，后续将支持生成编译产物加快编译速度等功能。
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