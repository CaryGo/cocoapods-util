module Pod
    class XCFrameworkBuilder
        def initialize(name, source_dir, create_swiftinterface)
            @name = name
            @source_dir = source_dir
            @create_swiftinterface = create_swiftinterface
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
            os_archs = []
            sim_archs = []
            frameworks_path = Array.new()
            if archs.empty?
                UI.puts "framework文件中没有检查到任何编译架构，请使用`lipo -info`或`lipo -archs`检查文件支持的架构。"
                return
            elsif archs.count == 1
                frameworks_path += [framework_path]
            else
                # 如果是MacOSX不需要处理
                is_macosx_platform = `strings #{lib_path} | grep -E -i '/Platforms/MacOSX.platform' | head -n 1`
                if is_macosx_platform.empty?
                    os_archs = archs & ['arm64', 'armv7', 'armv7s']
                    sim_archs = archs & ['i386', 'x86_64']
                end
            end

            # check_swiftmodule
            swiftmodule_path = Dir.glob("#{framework_path}/Modules/*.swiftmodule").first
            unless swiftmodule_path.nil?
                if Dir.glob("#{swiftmodule_path}/*.swiftinterface").empty?
                    unless @create_swiftinterface
                        UI.puts "Framework中包含swiftmodule文件，但是没有swiftinterface，无法创建xcframework，请检查Framework文件。或者使用`--create-swiftinterface`参数"
                        return
                    end
                    arm_swiftinterface = Pathname.new("#{swiftmodule_path}/arm.swiftinterface")
                    File.new(arm_swiftinterface, "w+").close
                end
            end
    
            # 1. remove iphone os/simulator paths
            clean_intermediate_path

            # 2. copy iphoneos framework
            if os_archs.count > 0
                path = Pathname.new("#{@source_dir}/#{iphoneos_target_path}")
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
            # 3. copy iphonesimulation framework
            if sim_archs.count > 0
                path = Pathname.new("#{@source_dir}/#{iphonesimulator_target_path}")
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

            # 4. build xcframework
            command = "xcodebuild -create-xcframework -framework #{frameworks_path.join(' -framework ')} -output #{@source_dir}/#{@name}.xcframework 2>&1"
            output = `#{command}`.lines.to_a
            result = $?
    
            # 5. remove iphone os/simulator paths
            clean_intermediate_path

            # show error
            if result.exitstatus != 0
                puts UI::BuildFailedReport.report(command, output)
                Process.exit
            end
            UI.puts("Generate #{@name}.xcframework succees")
        end

        private
        def clean_intermediate_path
            [iphoneos_target_path, iphonesimulator_target_path].each do |path|
                file_path = "#{@source_dir}/#{path}"
                if File.exist? file_path
                    FileUtils.rm_rf(file_path)
                end
            end
        end

        def iphoneos_target_path
            "#{@name}_iphoneos"
        end
        def iphonesimulator_target_path
            "#{@name}_iphonesimulator"
        end
    end
end