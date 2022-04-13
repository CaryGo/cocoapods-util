module Pod
    class XCFrameworkBuilder
        def initialize(name, source_dir)
            @name = name
            @source_dir = source_dir
        end

        def build_static_xcframework
            UI.puts("Generate static xcframework #{@name}")
            
            framework_path = "#{@source_dir}/#{@name}.framework"
            lib_path = "#{framework_path}/Versions/A/#{@name}"
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
                `lipo #{extract_archs.join(' ')} "#{lib_path}" -o "#{fwk_path}/Versions/A/#{@name}"`
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
                `lipo #{extract_archs.join(' ')} "#{lib_path}" -o "#{fwk_path}/Versions/A/#{@name}"`
            end

            # 3. build xcframework
            command = "xcodebuild -create-xcframework -framework #{frameworks_path.join(' -framework ')} -output #{@source_dir}/#{@name}.xcframework 2>&1"
            output = `#{command}`.lines.to_a
            if $?.exitstatus != 0
                puts UI::BuildFailedReport.report(command, output)
                Process.exit
            end
    
            # 4. remove iphone os/simulation paths
            ['iphoneos', 'iphonesimulation'].each do |path|
                file_path = "#{@source_dir}/#{path}"
                if File.exist? file_path
                    Pathname.new(file_path).rmtree
                end
            end

            # 5. generate success
            UI.puts("Generate xcframework #{@name} succees")
        end
    end
end