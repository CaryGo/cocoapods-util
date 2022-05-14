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
              @showmore = argv.flag?('showmore', false) || @name
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
                installed = pod_installed
                help! "没有找到#{@name}组件的相关信息，请检查输入的组件名称" unless installed.include?(@name)
                check_componment_with_name(@name)
              end
            end

            private
            def check_all_componment
              installed = pod_installed
              installed.each_index do |index|
                name = installed[index]
                check_componment_with_name(name, index+1)
              end
            end

            def check_componment_with_name(name, index=1)
              internal_data = @lockfile.internal_data
              internal_data["PODS"].each do |item|
                info = item.keys.first if item.is_a?(Hash) && item.count == 1
                info = item if item.is_a?(String)
                if info =~ /^#{name}[^\/]*$/
                  tag = info.match(/\(.*\)/) || ''
                  UI.puts "#{index}).".red " #{name} ".green "#{tag}".yellow
                  
                  # repo spec
                  repo_name = pod_spec_repos[name]
                  UI.puts "   - SPEC REPO: ".yellow "#{repo_name}".green unless repo_name.nil?
                  
                  # external sources
                  external = internal_data['EXTERNAL SOURCES'][name]
                  external.each { |key, value| UI.puts "   - #{key}: ".yellow "#{value}".green } unless external.nil?

                  show_moreinfo(name) if @showmore
                  break
                end
              end
            end

            def show_moreinfo(name)
              subspecs = Array.new
              dependencies = Array.new
              @lockfile.internal_data["PODS"].each { |item|
                info = item.keys.first if item.is_a?(Hash) && item.count == 1
                info = item if item.is_a?(String)
                if info =~ /^#{name}.*$/
                  subspecs.push(info.match(/^[^\s]*/)) if info =~ /^#{name}\/.*$/
                  if item.is_a?(Hash)
                    item.each_value do |value| 
                      value.each {|dependency| dependencies.push(dependency.to_s) unless dependency =~ /^#{name}/ }
                    end
                  elsif item.is_a?(String)
                    dependencies.push(item.to_s) unless item =~ /^#{name}/
                  end
                end
              }
              subspecs.uniq!
              dependencies.uniq!
              UI.puts "   - SUBSPEC: ".yellow "#{subspecs.join('、')}".green unless subspecs.empty?
              UI.puts "   - DEPENDENCIES: ".yellow "#{dependencies.join('、')}".green unless dependencies.empty?
            end

            def pod_installed
              if @installed
                return @installed                  
              end
              @installed = Array.new
              @lockfile.internal_data["SPEC CHECKSUMS"].each_key do |item|
                @installed.push(item)
              end
              @installed
            end

            def pod_spec_repos
              if @spec_repos
                return @spec_repos                
              end
              @spec_repos = Hash.new
              @lockfile.internal_data["SPEC REPOS"].each do |key, value|
                value.each {|item| @spec_repos[item] = key } if value.is_a?(Array)
              end
              @spec_repos
            end
          end
        end
      end
    end
  end