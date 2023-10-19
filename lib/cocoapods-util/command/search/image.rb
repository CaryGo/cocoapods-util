require 'pathname'
require 'fileutils'

module Pod
    class Command
      class Util < Command
        class Search < Util
          class Image < Search
            self.summary = '搜索组件（从工程中抽离的）所在路径的文件中引用的图片资源，列出图片名称和所在位置。'
            self.command = 'image'
            self.arguments = [
            ]
            def self.options
              [
                ['--modulepath', '组件所在路径'],
                ['--projectpath', '项目所在路径'],
                ['--outputpath', '搜索结果输出路径']
              ]
            end

            def initialize(argv)
                @modulepath = argv.option('modulepath')
                @projectpath = argv.option('projectpath')
                @outputpath = argv.option('outputpath')
                super
            end
  
            def validate!
                help! "modulepath和projectpath是必传的！" if @modulepath.nil? or @projectpath.nil?
                super
            end
  
            def run
              search
            end

            def search
              def search_files(path)
                files = []
                path.children().each { |child| files += search_files(child) } if path.directory?
                files += [path] if path.to_s =~ /.*\.(h|m|mm|pch)$/
                files
              end

              imageNames = []
              files = search_files(module_path)
              files.each do |file_path|
                all, handle, not_handle = [], [], []

                # 读取文件所有的行
                lines = File.readlines(file_path)
                # 遍历每一行内容（只处理一行的内容，如果写个[UIImage imageNamed:]还写到多行里面去，确实处理不了）
                File.foreach(file_path).with_index {|line, num|
                  # 正则
                  regex = '\[\s*UIImage\s*imageNamed\s*:\s*'
                  pattern1 = regex + '[^\]]*\]' # 粗略匹配
                  pattern2 = regex + '@"[^"]*"\s*\]' # 匹配直接使用图片名称的地方

                  match_pattern1 = line =~ /#{pattern1}/
                  match_pattern2 = line =~ /#{pattern2}/

                  if match_pattern1
                    line_matched = "line#{num}：#{line.match(/#{pattern1}/)}"
                    all << line_matched

                    if match_pattern2
                      handle << line_matched
                      imageNames << line_matched.match(/(?<=")[^"]*(?=")/).to_s
                    else
                      not_handle << line_matched
                    end
                  end
                }

                if all.size > 0
                  log_message "检查文件：#{file_path}"
                  log_message "检索到所有调用：\n#{all.join('\n')}"
                  log_message "检索到可以处理的调用：\n#{handle.join('\n')}" if handle.size > 0
                  log_message "检索到不能处理的调用：\n#{not_handle.join('\n')}" if not_handle.size > 0
                  log_message "\n"
                end
              end
              log_message "搜索到的图片调用有#{imageNames.size}处"
              imageNames.uniq!
              log_message "去重后的图片名称有#{imageNames.size}个，名称是：\n#{imageNames.join('\n')}"
              @searchedImageNames = imageNames

              puts "搜索到图片名称 #{imageNames.size} 个，去 #{log_file} 查看一下日志吧"
            end

            def query
              def query_images(path)
                if path.directory? && path.to_s =~ /.*\.imageset$/
                  imageset_name = path.basename.to_s.gsub(/.imageset$/, '')
                  return [path] if @searchedImageNames.include?(imageset_name)
                end
                files = []
                path.children().each { |child| files += query_images(child) } if path.directory? 
                if path.to_s =~ /.*\.(png|jpg|jpeg|webp|heic|gif)/
                  image_name = path.basename.sub_ext('').to_s
                  match_name = image_name.gsub(/@[0-9]+\.?[0-9]*x$/, '')
                  if @searchedImageNames.include?(match_name)
                    files += [path]
                  end
                end
                files
              end
        
              def create_contents_json(path)
                image_assets_content = <<ASSETS_CONTENT
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
ASSETS_CONTENT
                file_path = path + "Contents.json"
                File.write(file_path, image_assets_content)
              end
        
              target_path = output_path + 'Assets'
              target_path.rmtree if target_path.exist?
              target_path.mkpath
        
              xcassets_path = target_path + 'images.xcassets'
              xcassets_path.mkpath
              create_contents_json(xcassets_path)
        
              image_path = target_path + 'images'
              image_path.mkpath
        
              queryed_images = []
        
              find_files = query_images(project_path)
              find_files.each do |file_path|
                if file_path.to_s =~ /.*\.imageset$/
                  queryed_images << file_path.basename.to_s.gsub(/.imageset$/, '')
                  FileUtils.cp_r(file_path, xcassets_path)
                else
                  queryed_images << file_path.basename.sub_ext('').to_s.gsub(/@[0-9]+\.?[0-9]*x$/, '')
                  FileUtils.cp_r(file_path, image_path)
                end
              end
        
              queryed_images.uniq!
        
              missing_images = @searchedImageNames - queryed_images
              if missing_images.size > 0
                log_message "部分图片未找到：\n#{missing_images.join('\n')}"
              end
            end

            def log_message(message)
              `echo "#{message}" >> "#{log_file}"`
            end

            def log_file
              @log_file ||= begin
                log_file = output_path + 'log.txt'
                log_file.rmtree if log_file.exist?
                log_file
              end
              @log_file
            end

            private
            def module_path
                @module_path ||= Pathname.new(@modulepath)
                @module_path
            end

            def project_path
                @project_path ||= Pathname.new(@projectpath)
                @project_path
            end

            def output_path
                @output_path ||= begin
                    path = (@outputpath || `pwd`.chomp)
                    outputpath = Pathname.new(path) + 'search_images'
                    outputpath.rmtree if outputpath.exist?
                    outputpath.mkpath
                    outputpath
                end
                @output_path
            end
          end
        end
      end
    end
  end