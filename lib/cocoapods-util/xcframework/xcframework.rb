require 'cocoapods-util/xcframework/xcramework_build.rb'

module Pod
    class Command
      class Util < Command
          class XCFramework < Util
              self.summary = '生成XCFramework'
              self.command = 'xcfwk'
              self.arguments = [
                CLAide::Argument.new('NAME', true),
              ]
      
              def self.options
                [
                  ['--force',   '强制生成新的xcframework.']
                ]
              end
      
              def initialize(argv)
                @name = argv.shift_argument
                @force = argv.flag?('force')
                super
              end
      
              def validate!
                super
                help! '必须传入framework路径或名称.' unless @name
              end
      
              def run
                if @name.nil? || (File.exist? @name) == false
                  help! 'Unable to find a framework with path or name.'
                  return
                end

                source_dir, basename = File.split(@name)
                framework_name = basename.split('.').first
                Dir.chdir(source_dir)

                target_dir = "#{source_dir}/#{framework_name}.xcframework"
                if File.exist? target_dir
                  if @force
                    Pathname.new(target_dir).rmtree
                  else
                    help! "#{target_dir}已经存在"
                  end
                end
                
                builder = XCFrameworkBuilder.new(
                  framework_name,
                  source_dir
                )
                builder.build_static_xcframework
              end
          end
      end
    end
  end