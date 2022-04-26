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
              @name = argv.option('name')
              @all_componment = argv.flag?('all', true) && (@name.nil? || @name.empty?)
              super
            end
  
            def validate!
              super
            end
  
            def run
              @lockfile = Pod::Config.instance.lockfile
              help! '没有查找到Podfile.lock文件，你需要在Podfile所在目录执行。' unless @lockfile

              if @all_componment
                check_all_componment
              else
                dependencys = @lockfile.internal_data["DEPENDENCIES"]
                dependencys.select! {|item|
                  item =~ /^#{@name}.*$/
                }
                help! "没有找到#{@name}组件的相关信息，请检查输入的组件名称" if dependencys.empty?
                tag_info = check_componment_with_name(@name)
                UI.puts "1). #{dependencys.shift} #{tag_info}".green
              end
            end

            private
            def check_all_componment
              internal_data = @lockfile.internal_data
              dependencys = internal_data["DEPENDENCIES"]
              dependencys.each_index {|index|
                name = dependencys[index]
                tag_info = check_componment_with_name(name)
                UI.puts "#{index+1}). #{name} #{tag_info}".green
              }
            end

            def check_componment_with_name(name)
              name = name.split(' ').first
              tag_info = nil
              @lockfile.internal_data["PODS"].each {|item|
                if item.is_a?(Hash)
                  item.each {|key, value|
                    if key =~ /^#{name}\s+\([^\)]*\)$/
                      tag_info = key.gsub(/^#{name}\s+/, '')
                    end
                  }
                elsif item.is_a?(String)
                  if item =~ /^#{name}\s+\([^\)]*\)$/
                    tag_info = item.gsub(/^#{name}\s+/, '')
                  end
                end
                break unless tag_info.nil?
              }
              tag_info
            end
          end
        end
      end
    end
  end