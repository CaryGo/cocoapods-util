require 'cocoapods/config'

module Pod
    class Command
      class Util < Command
        class Install < Util
          class List < Install
            self.summary = '列出pod install安装的组件信息。'
            self.command = 'list'
            def self.options
                [
                  ['--all', 'list all component.'],
                  ['--name', 'componment name.']
                ]
            end

            def initialize(argv)
                @component_name = argv.option('name')
                @all_componment = argv.flag?('all', true) && @component_name.nil? 
                super
            end
  
            def validate!
              super
            end
  
            def run
                lockfile = Pod::Config.instance.lockfile
                help! '你需要在Podfile所在目录执行。' unless lockfile

                puts 'xxx'
            end
          end
        end
      end
    end
  end