require 'cocoapods-util/package/package'
require 'cocoapods-util/xcframework/xcframework'
require 'cocoapods-util/libsource/source'

require 'cocoapods-util/cocoapods-extend/extend'

module Pod
  class Command
    class Util < Command
      self.summary = '一个CocoaPods常用插件功能的集合'
      self.description = <<-DESC
      一个CocoaPods常用插件功能的集合，解决日常开发中遇到的一些问题。
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