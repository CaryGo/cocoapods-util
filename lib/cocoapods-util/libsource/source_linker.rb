class SourceLinker
include Pod
    attr_accessor :allow_ask_source_path, :source_path, :compile_path

    def initialize(file_name, file_type, source_dir, link_type, force_link)
        # 允许询问源码路径，默认为false
        @allow_ask_source_path = false
        @link_type = link_type

        @file_name = file_name.gsub(/^lib/, '')
        @file_type = file_type
        @source_dir = source_dir
        @force_link = force_link
    end
        
    def execute
        compile_dir_path = if @compile_path
                                @compile_path
                            else
                                check_compile(get_lib_path)
                            end
        if compile_dir_path.nil? || compile_dir_path.empty?
            UI.puts "没有获取到可执行文件的编译路径，链接结束。"
            return
        end

        case @link_type
        when :link
            add_link(compile_dir_path)
        when :unlink
            remove_link(compile_dir_path)
        else
            linked_path = get_linked_path(compile_dir_path)
            check_linked(get_lib_path, linked_path)
        end
    end

    private

    def remove_link(compile_dir_path)
        linked_path = get_linked_path(compile_dir_path)
        if File.exist? linked_path
            if File.symlink?(linked_path)
                File.unlink(linked_path)
                UI.puts "已移除可执行文件的源码映射关系。"
            else
                UI.puts "映射文件不是软链接。"
            end
        else
            UI.puts "映射文件不存在。"
        end
    end

    def add_link(compile_dir_path)
        linked_path = get_linked_path(compile_dir_path)
        if File.exist? linked_path
            if File.symlink?(linked_path)
                if @force_link
                    File.unlink(linked_path)
                    # Pathname.new(linked_path).rmtree
                else
                    UI.puts "可执行文件的编译路径已经存在映射关系，您可以尝试使用`--force`。请检查路径：#{compile_dir_path}".red
                    return
                end
            else
                UI.puts "文件编译路径已存在，并不是软链接。请检查路径：#{compile_dir_path}".red
                return
            end
        end

        if @source_path.nil? && @allow_ask_source_path
            @source_path = get_stdin("您没有设置将要映射的源码路径，请输入（或者拖动路径到终端）...")
        end
        if @source_path.nil? || @source_path.empty?
            UI.puts "没有将要链接的源码路径，链接结束。"
            return
        else
            @source_path = File.expand_path(@source_path)
            unless File.exist?(@source_path) && File.directory?(@source_path)
                UI.puts "将要链接的源码路径不存在或不是文件目录，链接结束。"
                return
            end
        end

        compile_dir = Pathname.new(compile_dir_path)
        unless compile_dir.exist?
            begin
                compile_dir.mkdir
            rescue Exception => e 
                # puts e.backtrace.inspect 
                UI.puts "创建可执行文件的编译路径失败，可能是因为权限问题，请检查`#{compile_dir}`\n\n错误信息：#{e.message}".red
                UI.puts "您可以使用命令创建目录：`sudo mkdir -p #{compile_dir}`"
                return
            end
        end

        # 链接
        File.symlink(@source_path , linked_path)
        check_linked(get_lib_path, linked_path)
    end

    def check_linked(lib_file, linked_path)
        file = `dwarfdump "#{lib_file}" | grep -E "DW_AT_decl_file.*\.(m|mm|c)" | head -1 | cut -d \\" -f2`.chomp!
        basename = File.basename(file)
        files = Dir.glob("#{linked_path}/**/#{basename}")
        unless File.exist?(file)
            UI.puts "#{file}文件不存在，请检查源码的版本或存储位置"
            return
        end
        UI.puts "链接成功，链接路径#{linked_path}"
    end

    def get_stdin(message)
        UI.puts "#{message}".red
        print "请输入--> ".green
        val = STDIN.gets.chomp.strip
        val
    end

    def get_linked_path(compile_dir_path)
        if @source_path.nil? || @source_path.empty?
            linked_path = "#{compile_dir_path}/#{@file_name}"
        else
            basename = File.basename(@source_path)
            linked_path = "#{compile_dir_path}/#{basename}" 
        end
        linked_path
    end

    def get_lib_path
        if @lib_path
            @lib_path
        else
            case @file_type
            when 'a'
                @lib_path = check_realpath("lib#{@file_name}.a", @source_dir)
            when 'framework'
                framework_path = "#{@source_dir}/#{@file_name}.framework"
                @lib_path = check_realpath(@file_name, framework_path)
            when 'xcframework'
                xcframework_path = "#{@source_dir}/#{@file_name}.xcframework"
                framework_path = Dir.glob("#{xcframework_path}/**/*.framework").first
                raise "没有找到framework，请检查xcframework文件" unless framework_path
                @lib_path = check_realpath(@file_name, framework_path)
            end
            @lib_path
        end
    end

    def check_realpath(lib_file, dir_path)
        lib_path = "#{dir_path}/#{lib_file}"
        if File.exist? lib_path
            # 如果可执行文件为软链接类型，获取realpath
            if File.ftype(lib_path) == 'link'
                realpath = File.readlink(lib_path) 
                lib_path = "#{dir_path}/#{realpath}"
            end
            lib_path
        else
            raise "没有找到可执行文件，请检查输入的文件或路径"
        end
    end

    def check_compile(lib_path)
        compile_dir_path = `dwarfdump "#{lib_path}" | grep "AT_comp_dir" | head -1 | cut -d \\" -f2`.chomp!
        compile_dir_path
    end
end