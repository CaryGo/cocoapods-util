require 'cocoapods-util/package/package'
require 'cocoapods-util/xcframework/xcframework'

module Pod
  class Command
    class Util < Command
      self.summary = 'pod插件工具'
      self.description = <<-DESC
      pod插件入口，使用`pod util --help`查看支持功能。
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