require 'cocoapods/config'

module Pod
    class Command
      class Util < Command
        class Install < Util
          class List < Install
            self.summary = '列出pod install安装的组件信息，Podfile.lock不传则在当前目录查找'
            self.command = 'list'
            self.arguments = [
              CLAide::Argument.new('Podfile.lock', false)
            ]
            def self.options
              [
                ['--all', 'list all component.'],
                ['--name', 'componment name.'],
                ['--showmore', 'show more information.']
              ]
            end

            def initialize(argv)
              @lockfile_path = argv.shift_argument
              @name = argv.option('name')
              @all_componment = argv.flag?('all', true) && (@name.nil? || @name.empty?)
              @showmore = argv.flag?('showmore', false)
              super
            end
  
            def validate!
              super
            end
  
            def run
              if @lockfile_path.nil?
                @lockfile = Pod::Config.instance.lockfile
              else
                @lockfile = Lockfile.from_file(Pathname.new(@lockfile_path))
              end
              help! '没有查找到Podfile.lock文件，你需要在Podfile所在目录执行或传入Podfile.lock文件路径。' unless @lockfile

              if @all_componment
                check_all_componment
              else
                dependencys = @lockfile.internal_data["DEPENDENCIES"].compact
                dependencys.select! {|item|
                  item =~ /^#{@name}.*$/
                }
                help! "没有找到#{@name}组件的相关信息，请检查输入的组件名称" if dependencys.empty?
                tag_info = check_componment_with_name(@name)
                UI.puts "1).".red " #{dependencys.first} ".green "#{tag_info}".yellow
                if @showmore
                  repo_name = check_repos(@name)
                  UI.puts "   - SPEC REPO: #{repo_name}".green unless repo_name.nil?
                end
              end
            end

            private
            def check_all_componment
              internal_data = @lockfile.internal_data
              dependencys = internal_data["DEPENDENCIES"]
              dependencys.each_index {|index|
                name = dependencys[index]
                tag_info = check_componment_with_name(name)
                UI.puts "#{index+1}).".red " #{name} ".green "#{tag_info}".yellow
                if @showmore
                  repo_name = check_repos(name)
                  UI.puts "   - SPEC REPO: #{repo_name}".green unless repo_name.nil?
                end
              }
            end

            def check_componment_with_name(name)
              name = name.split(' ').first
              tag = nil
              @lockfile.internal_data["PODS"].each {|item|
                if item.is_a?(Hash)
                  item.each_key {|key|
                    if key =~ /^#{name}\s+\([^\)]*\)$/
                      tag = key.gsub(/^#{name}\s+/, '')
                      break
                    end
                  }
                elsif item.is_a?(String)
                  if item =~ /^#{name}\s+\([^\)]*\)$/
                    tag = item.gsub(/^#{name}\s+/, '')
                  end
                end
                break unless tag.nil?
              }
              tag
            end

            def check_repos(name)
              name = name.split(' ').first
              repo_name = nil
              @lockfile.internal_data["SPEC REPOS"].each {|key, value|
                if value.is_a?(Array)
                  value.each {|item|
                    if item == "#{name}"
                      repo_name = key
                      break
                    end
                  }
                end
                break unless repo_name.nil?
              }
              repo_name
            end
          end
        end
      end
    end
  end