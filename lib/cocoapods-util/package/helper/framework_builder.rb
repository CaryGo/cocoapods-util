module Pod
    class Builder
        private
        def create_framework(os_name = '')
            @fwk = Framework::Tree.new(@spec.name, "#{@platform.name.to_s}/#{os_name}")
            @fwk.make
            @fwk
        end

        def framework_build_static_library(build_root = 'build')
            static_libs = static_libs_in_sandbox(build_root)
            output = @fwk.versions_path + Pathname.new(@spec.name)
            `lipo -create -output #{output} #{static_libs.join(' ')}`
        end

        def framework_copy_headers(build_root = 'build')
            headers_source_root = "#{@public_headers_root}/#{@spec.name}"
      
            Dir.glob("#{headers_source_root}/**/*.h").
              each { |h| `ditto #{h} #{@fwk.headers_path}/#{h.sub(headers_source_root, '')}` }
      
            # check swift headers
            swift_headers = Dir.glob("#{@static_sandbox_root}/#{build_root}/#{os_build_name(build_root)}/#{@spec.name}/**/*-{Swift,umbrella}.h")
            swift_headers.each { |h| `cp -rp #{h.gsub(/\s/, "\\ ")} #{@fwk.headers_path}/` }
      
            # check swiftmodule files
            swiftmodule_path = "#{@static_sandbox_root}/#{build_root}/#{os_build_name(build_root)}/#{@spec.name}/#{@spec.name}.swiftmodule"
            if File.exist? swiftmodule_path
              @fwk.module_map_path.mkpath unless @fwk.module_map_path.exist?
              `cp -rp #{swiftmodule_path.to_s} #{@fwk.module_map_path}/`
            end
      
            # umbrella header name
            header_name = "#{@spec.name}"
            header_name = "#{@spec.name}-umbrella" if File.exist? "#{@fwk.headers_path}/#{@spec.name}-umbrella.h"
      
            # If custom 'module_map' is specified add it to the framework distribution
            # otherwise check if a header exists that is equal to 'spec.name', if so
            # create a default 'module_map' one using it.
            if !@spec.module_map.nil?
              module_map_file = @file_accessors.flat_map(&:module_map).first
              module_map = File.read(module_map_file) if Pathname(module_map_file).exist?
            elsif File.exist?("#{@fwk.headers_path}/#{header_name}.h")
                if swift_headers.count > 0
                    module_map = <<MAP
framework module #{@spec.name} {
    umbrella header "#{header_name}.h"

    export *
    module * { export * }
}
module #{@spec.name}.Swift {
    header "#{@spec.name}-Swift.h"
    requires objc
}
MAP
                  else
                      module_map = <<MAP
framework module #{@spec.name} {
    umbrella header "#{header_name}.h"

    export *
    module * { export * }
}
MAP
                  end
            end
      
            unless module_map.nil?
              @fwk.module_map_path.mkpath unless @fwk.module_map_path.exist?
              File.write("#{@fwk.module_map_path}/module.modulemap", module_map)
            end
        end

        def framework_copy_license
            license_file = @spec.license[:file] || 'LICENSE'
            `cp "#{license_file}" .` if Pathname(license_file).exist?
        end
        def framework_copy_resources(build_root = 'build')
            unless @framework_contains_resources
                # copy resources
                platform_path = Pathname.new(@platform.name.to_s)
                platform_path.mkdir unless platform_path.exist?
                
                bundles = Dir.glob("#{@static_sandbox_root}/#{build_root}/#{os_build_name(build_root)}/#{@spec.name}/*.bundle")
                resources = expand_paths(@spec.consumer(@platform).resources)
                if bundles.count > 0 || resources.count > 0
                  resources_path = platform_path + "Resources"
                  resources_path.mkdir unless resources_path.exist?
                  if bundles.count > 0
                    `cp -rp #{@static_sandbox_root}/#{build_root}/#{os_build_name(build_root)}/#{@spec.name}/*.bundle #{resources_path} 2>&1`
                  end
                  if resources.count > 0
                    `cp -rp #{resources.join(' ')} #{resources_path}`
                  end
                end
        
                # delete framework resources
                @fwk.delete_resources if @fwk
                return
            end
    
            bundles = Dir.glob("#{@static_sandbox_root}/#{build_root}/#{os_build_name(build_root)}/#{@spec.name}/*.bundle")
            `cp -rp #{@static_sandbox_root}/#{build_root}/#{os_build_name(build_root)}/#{@spec.name}/*.bundle #{@fwk.resources_path} 2>&1`
            resources = expand_paths(@spec.consumer(@platform).resources)
            if resources.count == 0 && bundles.count == 0
                @fwk.delete_resources
                return
            end
            if resources.count > 0
                `cp -rp #{resources.join(' ')} #{@fwk.resources_path}`
            end
        end
    end
end