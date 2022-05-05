module Pod
    class Builder
        private
        def create_library
            @library_platform_path = Pathname.new(@platform.name.to_s)
            @library_platform_path.mkdir unless @library_platform_path.exist?

            generate_static_library
            library_copy_headers
            library_copy_resources
        end

        def generate_static_library
            os_static_libs = static_libs_in_sandbox('build')
            sim_static_libs = static_libs_in_sandbox('build-sim') unless @exclude_sim

            # check appletv archs
            if @platform.name.to_s == 'tvos'
                archs = []
                os_static_libs.each { |lib|
                    archs += `lipo -archs #{lib}`.split
                    archs.uniq!
                }
                sim_static_libs.each { |lib| 
                    remove_archs = `lipo -archs #{lib}`.split & archs
                    `lipo -remove #{remove_archs.join(' -remove ')} #{lib} -output #{lib}` unless remove_archs.empty?
                }
            end

            output = @library_platform_path + "lib#{@spec.name}.a"
            `lipo -create -output #{output} #{os_static_libs.join(' ')} #{sim_static_libs.join(' ')}`
        end

        def library_copy_headers
            headers_source_root = "#{@public_headers_root}/#{@spec.name}"
            headers = Dir.glob("#{headers_source_root}/**/*.h")
            if headers.count > 0
                headers_path = @library_platform_path + "Headers"
                headers_path.mkdir unless headers_path.exist?
                headers.each { |h| `ditto #{h} #{headers_path}/#{h.sub(headers_source_root, '')}` }
            end
        end
        def library_copy_resources(build_root = 'build')
            bundles = Dir.glob("#{@static_sandbox_root}/#{build_root}/#{os_build_name('build')}/#{@spec.name}/*.bundle")
            resources = expand_paths(@spec.consumer(@platform).resources)
            if bundles.count > 0 || resources.count > 0
                resources_path = @library_platform_path + "Resources"
                resources_path.mkdir unless resources_path.exist?
                if bundles.count > 0
                `cp -rp #{@static_sandbox_root}/#{build_root}/#{os_build_name('build')}/#{@spec.name}/*.bundle #{resources_path} 2>&1`
                end
                if resources.count > 0
                `cp -rp #{resources.join(' ')} #{resources_path}`
                end
            end
        end
    end
end