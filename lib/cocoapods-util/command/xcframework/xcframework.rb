require_relative 'xcframework_build.rb'

module Pod
    class Command
      class Util < Command
          class XCFramework < Util
              self.summary = '根据传入framework在同目录下生成xcframework'
              self.description = <<-DESC
              根据传入framework在同目录下生成xcframework
              DESC
              self.command = 'xcframework'
              self.arguments = [
                CLAide::Argument.new('FRAMEWORK_PATH', true)
              ]
      
              def self.options
                [
                  ['--force',   '覆盖已经存在的文件'],
                  ['--create-swiftinterface', '有编译swift文件的framework，如果不包含swiftinterface则无法生成xcframework。
                    设置该参数会生成一个swiftinterface文件解决create失败的问题。']
                ]
              end
      
              def initialize(argv)
                @file_path = argv.shift_argument
                @force = argv.flag?('force')
                @create_swiftinterface = argv.flag?('create-swiftinterface')
                super
              end
      
              def validate!
                super
                help! '必须传入framework路径或名称.' unless @file_path
              end
      
              def run
                # 获取真实路径，~ 为进程所有者的主目录
                @file_path = File.expand_path(@file_path)
                if !File.exist?(@file_path) || !(@file_path =~ /\.framework$/)
                  help! "路径不存在或传入的路径不是framework文件"
                  return
                end

                source_dir = File.dirname(@file_path)
                framework_name = File.basename(@file_path, ".framework")

                target_dir = "#{source_dir}/#{framework_name}.xcframework"
                if File.exist?(target_dir)
                  if @force
                    Pathname.new(target_dir).rmtree
                  else
                    help! "#{target_dir}已经存在，使用`--force`可以覆盖已有文件"
                  end
                end
                
                builder = XCFrameworkBuilder.new(
                  framework_name,
                  source_dir,
                  @create_swiftinterface
                )
                builder.build_static_xcframework
              end
          end
      end
    end
  end