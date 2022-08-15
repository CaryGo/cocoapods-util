require_relative 'developer/identifier'
require_relative 'developer/mobileprovision'
module Pod
    class Command
      class Util < Command
        class Developer < Util
            self.summary = '开发者扩展功能。如列出安装证书、安装的mobileprovision文件等'
            self.description = <<-DESC
            对苹果开发者的扩展功能。
            DESC
            self.command = 'dev'
            self.abstract_command = true
        end
    end
  end
end
