module Pod
    class XCFrameworkBuilder
        def initialize(name, source_dir, create_swiftinterface)
            @name = name
            @source_dir = source_dir
            @create_swiftinterface = create_swiftinterface
        end

        def build_static_xcframework
            framework_path = "#{@source_dir}/#{@name}.framework"
            # 可执行文件名称
            lib_file = "#{@name}"
            # 可执行文件完整路径
            lib_path = "#{framework_path}/#{lib_file}"
            # 可执行文件不存在，退出
            unless File.exist? lib_path
                UI.puts("没有找到可执行文件，请检查输入的framework")
                return nil
            end
            # 如果可执行文件为软链接类型，获取realpath
            if File.ftype(lib_path) == 'link'
                lib_file = File.readlink(lib_path) 
                lib_path = "#{framework_path}/#{lib_file}"
            end

            framework_paths = Array.new
            # 获取可执行文件的支持架构
            archs = `lipo -archs #{lib_path}`.split
            os_archs = sim_archs = []
            if archs.empty?
                UI.puts "framework文件中没有检查到任何编译架构，请使用`lipo -info`或`lipo -archs`检查文件支持的架构。"
                return
            elsif archs.count == 1
                framework_paths += [framework_path]
            else
                platform = `strings #{lib_path} | grep -E -i '/Platforms/.*\.platform/' | head -n 1`.chomp!
                if platform =~ /iPhone[^\.]*\.platform/ # iphoneos iphonesimulator
                    os_archs = archs & ['arm64', 'armv7', 'armv7s']
                    sim_archs = archs & ['i386', 'x86_64']
                elsif platform =~ /MacOSX.platform/ # macosx
                    os_archs = ['arm64', 'x86_64']
                elsif platform =~ /Watch[^\.]*\.platform/ # watchos watchsimulator
                    os_archs = archs & ['armv7k', 'arm64_32']
                    sim_archs = archs & ['arm64', 'i386', 'x86_64']
                elsif platform =~ /AppleTV[^\.]*\.platform/ # appletvos appletvsimulator
                    os_archs = archs & ['arm64']
                    sim_archs = archs & ['x86_64'] # 'arm64' 'x86_64'
                else
                    os_archs = archs & ['arm64', 'armv7', 'armv7s']
                    sim_archs = archs & ['i386', 'x86_64']
                end
            end
    
            # 1. remove os/simulator paths
            clean_intermediate_path

            # 2. copy os framework
            if os_archs.count > 0
                path = Pathname.new("#{@source_dir}/#{os_target_path}")
                path.mkdir unless path.exist?
                `cp -a #{framework_path} #{path}/`
        
                fwk_path = "#{path}/#{@name}.framework"
                framework_paths += ["#{fwk_path}"]
                `lipo -extract #{os_archs.join(' -extract ')} "#{fwk_path}/#{lib_file}" -output "#{fwk_path}/#{lib_file}"`
            end
            # 3. copy simulation framework
            if sim_archs.count > 0
                path = Pathname.new("#{@source_dir}/#{simulator_target_path}")
                path.mkdir unless path.exist?
                `cp -a #{framework_path} #{path}/`

                fwk_path = "#{path}/#{@name}.framework"
                framework_paths += ["#{fwk_path}"]
                `lipo -extract #{sim_archs.join(' -extract ')} "#{fwk_path}/#{lib_file}" -output "#{fwk_path}/#{lib_file}"`
            end

            # 4. generate xcframework
            begin
                generate_xcframework(framework_paths)
            ensure # in case the create-xcframework fails; remove the temp directory.
                clean_intermediate_path
            end
        end

        def generate_xcframework(framework_paths)
            UI.puts("Generate #{@name}.xcframework")

            framework_paths.each { |framework_path|
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
            }

            # build xcframework
            command = "xcodebuild -create-xcframework -framework #{framework_paths.join(' -framework ')} -output #{@source_dir}/#{@name}.xcframework 2>&1"
            output = `#{command}`.lines.to_a
            result = $?
            # show error
            if result.exitstatus != 0
                puts UI::BuildFailedReport.report(command, output)
                Process.exit
            end
            UI.puts("Generate #{@name}.xcframework succees")
        end

        private
        def clean_intermediate_path
            [os_target_path, simulator_target_path].each do |path|
                file_path = "#{@source_dir}/#{path}"
                if File.exist? file_path
                    FileUtils.rm_rf(file_path)
                end
            end
        end

        def os_target_path
            "#{@name}_temp_os"
        end
        def simulator_target_path
            "#{@name}_temp_simulator"
        end
    end
end