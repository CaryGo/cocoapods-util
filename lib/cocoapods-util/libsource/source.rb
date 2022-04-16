require 'cocoapods-util/libsource/source_linker.rb'

module Pod
    class Command
      class Util < Command
          class Source < Util
              self.summary = '根据传入Framework添加源码软链接，需要传入或输入源码的路径'
              self.command = 'source'
              self.arguments = [
                CLAide::Argument.new('FRAMEWORK_PATH', true),
              ]
      
              def self.options
                [
                  ['--link', '链接源码'],
                  ['--unlink', '删除源码链接'],
                  ['--checklink', '检查源码链接'],
                  ['--force',   '覆盖已经添加的软链接'],
                  ['--source-path', '需要链接的源码的路径']
                ]
              end
      
              def initialize(argv)
                link = argv.flag?('link')
                @link_type = if argv.flag?('link')
                                :link 
                             elsif argv.flag?('unlink')
                                :unlink
                             elsif argv.flag?('checklink')
                                :checklink
                             else
                                :link
                             end

                @file_path = argv.shift_argument
                @force = argv.flag?('force')
                @source_path = argv.option('source-path', nil)
                super
              end
      
              def validate!
                super
                help! '必须传入需链接的library、framework或xcframework路径或名称.' unless @file_path
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
                  @force,
                  @source_path
                )
                linker.allow_ask_source_path = true
                linker.link_type = @link_type
                linker.execute
              end
          end
      end
    end
  end