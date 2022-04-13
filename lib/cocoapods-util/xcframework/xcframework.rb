require 'cocoapods-util/xcframework/xcramework_build.rb'

module Pod
    class Command
      class Util < Command
          class XCFramework < Util
              self.summary = '根据传入Framework在同目录下生成XCFramework。传入参数为framework路径'
              self.command = 'xcframework'
              self.arguments = [
                CLAide::Argument.new('FRAMEWORK_PATH', true),
              ]
      
              def self.options
                [
                  ['--force',   '覆盖已经存在的文件']
                ]
              end
      
              def initialize(argv)
                @file_path = argv.shift_argument
                @force = argv.flag?('force')
                super
              end
      
              def validate!
                super
                help! '必须传入framework路径或名称.' unless @file_path
              end
      
              def run
                if (File.exist? @file_path) == false || @file_path.split('.').last != 'framework'
                  help! "路径不存在或传入的路径不是framework文件"
                  return
                end

                source_dir, basename = File.split(@file_path)
                framework_name = File.basename(basename, '.framework')

                target_dir = "#{source_dir}/#{framework_name}.xcframework"
                if File.exist? target_dir
                  if @force
                    Pathname.new(target_dir).rmtree
                  else
                    help! "#{target_dir}已经存在，使用`--force`可以覆盖已有文件"
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