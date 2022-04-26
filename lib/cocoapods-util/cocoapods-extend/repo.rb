require 'cocoapods-util/cocoapods-extend/repo/push'
module Pod
    class Command
      class Util < Command
        class Repo < Util
            self.summary = 'cocoapods repo命令的扩展功能。'
            self.description = <<-DESC
            操作cocoapods的repo。如`pod util repo push`推送到私有仓库（可以设置参数跳过验证）。
            DESC
            self.command == 'repo'
            self.abstract_command = true
      end
    end
  end
end