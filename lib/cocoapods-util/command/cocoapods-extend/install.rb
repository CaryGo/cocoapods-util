require_relative 'install/list'
module Pod
    class Command
      class Util < Command
        class Install < Util
            self.summary = 'cocoapods install的扩展功能'
            self.description = <<-DESC
            使用`pod util install list`查看pod安装的组件
            DESC
            self.command = 'install'
            self.abstract_command = true
      end
    end
  end
end