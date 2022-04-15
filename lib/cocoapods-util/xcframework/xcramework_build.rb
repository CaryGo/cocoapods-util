module Pod
    class XCFrameworkBuilder
        def initialize(name, source_dir)
            @name = name
            @source_dir = source_dir
        end

        def build_static_xcframework
            UI.puts("Generate #{@name}.xcframework")
            
            framework_path = "#{@source_dir}/#{@name}.framework"
            # 可执行文件名称
            lib_file = "#{@name}"
            # 可执行文件完整路径
            lib_path = "#{framework_path}/#{lib_file}"
            # 可执行文件不存在，退出
            unless File.exist? lib_path
                UI.puts("没有找到可执行文件，请检查输入的framework")
                return
            end
            # 如果可执行文件为软链接类型，获取realpath
            if File.ftype(lib_path) == 'link'
                lib_file = File.readlink(lib_path) 
                lib_path = "#{framework_path}/#{lib_file}"
            end
            # 获取可执行文件的支持架构
            archs = `lipo -archs #{lib_path}`.split
            os_archs = archs & ['arm64', 'armv7', 'armv7s']
            sim_archs = archs & ['i386', 'x86_64']
    
            frameworks_path = Array.new()
            # 1. copy iphoneos framework
            if os_archs.count > 0
                path = Pathname.new("#{@source_dir}/iphoneos")
                path.mkdir unless path.exist?
                `cp -a #{framework_path} #{path}/`
                extract_archs = os_archs.map do |arch|
                    extract_arch = "-extract #{arch}"
                    extract_arch
                end
        
                fwk_path = "#{path}/#{@name}.framework"
                frameworks_path += ["#{fwk_path}"]
                `lipo #{extract_archs.join(' ')} "#{fwk_path}/#{lib_file}" -o "#{fwk_path}/#{lib_file}"`
            end
            # 2. copy iphonesimulation framework
            if sim_archs.count > 0
                path = Pathname.new("#{@source_dir}/iphonesimulation")
                path.mkdir unless path.exist?
                `cp -a #{framework_path} #{path}/`
                extract_archs = sim_archs.map do |arch|
                    extract_arch = "-extract #{arch}"
                    extract_arch
                end

                fwk_path = "#{path}/#{@name}.framework"
                frameworks_path += ["#{fwk_path}"]
                `lipo #{extract_archs.join(' ')} "#{fwk_path}/#{lib_file}" -o "#{fwk_path}/#{lib_file}"`
            end

            # 3. build xcframework
            command = "xcodebuild -create-xcframework -framework #{frameworks_path.join(' -framework ')} -output #{@source_dir}/#{@name}.xcframework 2>&1"
            output = `#{command}`.lines.to_a
            result = $?
    
            # 4. remove iphone os/simulation paths
            ['iphoneos', 'iphonesimulation'].each do |path|
                file_path = "#{@source_dir}/#{path}"
                if File.exist? file_path
                    Pathname.new(file_path).rmtree
                end
            end

            # show error
            if result.exitstatus != 0
                puts UI::BuildFailedReport.report(command, output)
                Process.exit
            end

            # 5. generate success
            UI.puts("Generate #{@name}.xcframework succees")
        end
    end
end