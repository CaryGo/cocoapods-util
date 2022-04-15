require 'cocoapods-util/libsource/source_linker.rb'

module Pod
    class Command
      class Util < Command
          class Source < Util
              self.summary = '根据传入Framework添加源码软链接，需要传入或输入源码的路径'
              self.command = 'linksource'
              self.arguments = [
                CLAide::Argument.new('FRAMEWORK_PATH', true),
              ]
      
              def self.options
                [
                  ['--force',   '覆盖已经添加的软链接']
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
                # 获取真实路径，~ 为进程所有者的主目录
                @file_path = File.expand_path(@file_path)
                if (File.exist? @file_path) == false || !(@file_path =~ /\.(a|framework|xcframework)$/)
                  help! "路径不存在或传入的路径不是framework文件"
                  return
                end

                source_dir, basename = File.split(@file_path)
                file_name, file_type = basename.split('.')

                linker = SourceLinker.new(
                  file_name,
                  file_type,
                  source_dir,
                  @force
                )
                linker.allow_ask_source_path = true
                linker.execute
              end
          end
      end
    end
  end