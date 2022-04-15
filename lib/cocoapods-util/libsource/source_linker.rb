class SourceLinker
include Pod
    attr_accessor :allow_ask_source_path, :islink

    def initialize(file_name, file_type, source_dir, force_link)
        # 允许询问源码路径，默认为false
        @allow_ask_source_path = false
        @islink = true

        @file_name = file_name
        @file_type = file_type
        @source_dir = source_dir
        @force_link = force_link
    end
        
    def execute
        puts "允许询问源码路径：#{@allow_ask_source_path}"

        compile_dir_path = check_compile(get_lib_path)
        puts compile_dir_path
    end

    private

    def get_lib_path
        if @lib_path
            @lib_path
        else
            case @file_type
            when 'a'
                @lib_path = check_realpath("#{@file_name}.a", @source_dir)
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
                lib_path
            else
                lib_path
            end
        else
            raise "没有找到可执行文件，请检查输入的文件或路径"
        end
    end

    def check_compile(lib_path)
        compile_dir_path = `dwarfdump "#{lib_path}" | grep "AT_comp_dir" | head -1 | cut -d \\" -f2`
        compile_dir_path
    end
end