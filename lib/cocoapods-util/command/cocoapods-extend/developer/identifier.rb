module Pod
    class Command
      class Util < Command
        class Developer < Util
          class Identifier < Developer
            self.summary = '列出本机安装的所有有效证书信息'
            self.command = 'identifier'
            self.arguments = [
            ]
            def self.options
                []
            end

            def initialize(argv)
              super
            end
  
            def validate!
              super
            end
  
            def run
                command = 'security find-identity -v -p codesigning'
                exec "#{command}"
            end
          end
        end
      end
    end
  end