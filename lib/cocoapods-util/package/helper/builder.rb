require 'cocoapods-util/xcframework/xcramework_build.rb'

module Pod
  class Builder
    def initialize(platform, static_installer, source_dir, static_sandbox_root, public_headers_root, spec, config, exclude_sim, exclude_archs, framework_contains_resources)
      @platform = platform
      @static_installer = static_installer
      @source_dir = source_dir
      @static_sandbox_root = static_sandbox_root
      @public_headers_root = public_headers_root
      @spec = spec
      @config = config
      @exclude_sim = exclude_sim
      @exclude_archs = exclude_archs
      @framework_contains_resources = framework_contains_resources

      @file_accessors = @static_installer.pod_targets.select { |t| t.pod_name == @spec.name }.flat_map(&:file_accessors)
    end

    def build(package_type)
      case package_type
      when :static_library
        build_static_library
      when :static_framework
        build_static_framework
      when :static_xcframework
        build_static_xcframework
      end
    end

    def build_static_library
      UI.puts("Building static library #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines)

      platform_path = Pathname.new(@platform.name.to_s)
      platform_path.mkdir unless platform_path.exist?

      output = platform_path + "lib#{@spec.name}.a"

      if @platform.name == :ios
        build_static_library_for_ios(output)
      else
        build_static_library_for_mac(output)
      end

      # 1. copy header
      headers_source_root = "#{@public_headers_root}/#{@spec.name}"
      headers = Dir.glob("#{headers_source_root}/**/*.h")
      if headers.count > 0
        headers_path = platform_path + "Headers"
        headers_path.mkdir unless headers_path.exist?
        headers.each { |h| `ditto #{h} #{headers_path}/#{h.sub(headers_source_root, '')}` }
      end

      # 2. copy resources
      copy_resources
    end

    def build_static_framework
      UI.puts("Building static framework #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines)

      create_framework
      output = @fwk.versions_path + Pathname.new(@spec.name)

      if @platform.name == :ios
        build_static_library_for_ios(output)
      else
        build_static_library_for_mac(output)
      end

      copy_headers
      copy_license
      copy_resources
    end

    def build_static_xcframework
      build_static_framework

      # gemerate xcframework
      xcbuilder = XCFrameworkBuilder.new(
        @spec.name,
        @platform.name.to_s,
        true
      )
      xcbuilder.build_static_xcframework
      # delete framework
      FileUtils.rm_rf("#{@platform.name.to_s}/#{@spec.name}.framework")
    end

    def build_sim_libraries(defines)
      if @platform.name == :ios && @exclude_sim == false
        xcodebuild(defines, '-sdk iphonesimulator', 'build-sim')
      end
    end

    def build_static_library_for_ios(output)
      static_libs = static_libs_in_sandbox('build')
      static_libs += static_libs_in_sandbox('build-sim') unless @exclude_sim
      libs = ios_architectures.map do |arch|
        library = "#{@static_sandbox_root}/build/#{@spec.name}-#{arch}.a"
        `libtool -arch_only #{arch} -static -o #{library} #{static_libs.join(' ')}`
        library
      end

      `lipo -create -output #{output} #{libs.join(' ')}`
    end

    def build_static_library_for_mac(output)
      static_libs = static_libs_in_sandbox('build')
      `libtool -static -o #{output} #{static_libs.join(' ')}`
    end

    def compile
      defines = "GCC_PREPROCESSOR_DEFINITIONS='$(inherited) PodsDummy_Pods_#{@spec.name}=PodsDummy_PodPackage_#{@spec.name}'"
      defines << ' ' << @spec.consumer(@platform).compiler_flags.join(' ')

      if @platform.name == :ios
        options = ios_build_options
      end

      xcodebuild(defines, options)

      defines
    end

    def copy_headers
      headers_source_root = "#{@public_headers_root}/#{@spec.name}"

      Dir.glob("#{headers_source_root}/**/*.h").
        each { |h| `ditto #{h} #{@fwk.headers_path}/#{h.sub(headers_source_root, '')}` }

      # check swift headers
      swift_headers = Dir.glob("#{@static_sandbox_root}/build/#{@config}-iphoneos/#{@spec.name}/**/*-{Swift,umbrella}.h")
      swift_headers.each { |h| 
        h_path = h.gsub(/\s/, "\\ ")
        `cp -rp #{h_path} #{@fwk.headers_path}/` 
      }

      # check swiftmodule files
      swiftmodule_path = "#{@static_sandbox_root}/build/#{@config}-iphoneos/#{@spec.name}/#{@spec.name}.swiftmodule"
      if File.exist? swiftmodule_path
        @fwk.module_map_path.mkpath unless @fwk.module_map_path.exist?
        `cp -rp #{swiftmodule_path.to_s} #{@fwk.module_map_path}/`
      end

      # umbrella header name
      header_name = "#{@spec.name}"
      if File.exist? "#{@fwk.headers_path}/#{@spec.name}-umbrella.h"
        header_name = "#{@spec.name}-umbrella"
      end

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

    def copy_license
      license_file = @spec.license[:file] || 'LICENSE'
      `cp "#{license_file}" .` if Pathname(license_file).exist?
    end

    def copy_resources
      unless @framework_contains_resources
        # copy resources
        platform_path = Pathname.new(@platform.name.to_s)
        platform_path.mkdir unless platform_path.exist?
        
        bundles = Dir.glob("#{@static_sandbox_root}/build/#{@config}-iphoneos/#{@spec.name}/*.bundle")
        resources = expand_paths(@spec.consumer(@platform).resources)
        if bundles.count > 0 || resources.count > 0
          resources_path = platform_path + "Resources"
          resources_path.mkdir unless resources_path.exist?
          if bundles.count > 0
            `cp -rp #{@static_sandbox_root}/build/#{@config}-iphoneos/#{@spec.name}/*.bundle #{resources_path} 2>&1`
          end
          if resources.count > 0
            `cp -rp #{resources.join(' ')} #{resources_path}`
          end
        end

        # delete framework resources
        @fwk.delete_resources if @fwk
        return
      end

      bundles = Dir.glob("#{@static_sandbox_root}/build/#{@config}-iphoneos/#{@spec.name}/*.bundle")
      `cp -rp #{@static_sandbox_root}/build/#{@config}-iphoneos/#{@spec.name}/*.bundle #{@fwk.resources_path} 2>&1`
      resources = expand_paths(@spec.consumer(@platform).resources)
      if resources.count == 0 && bundles.count == 0
        @fwk.delete_resources
        return
      end
      if resources.count > 0
        `cp -rp #{resources.join(' ')} #{@fwk.resources_path}`
      end
    end

    def create_framework
      @fwk = Framework::Tree.new(@spec.name, @platform.name.to_s)
      @fwk.make
    end

    def dependency_count
      count = @spec.dependencies.count

      @spec.subspecs.each do |subspec|
        count += subspec.dependencies.count
      end

      count
    end

    def expand_paths(path_specs)
      path_specs.map do |path_spec|
        Dir.glob(File.join(@source_dir, path_spec))
      end
    end

    def static_libs_in_sandbox(build_dir = 'build')
      UI.puts 'Excluding dependencies'
      if build_dir == 'build'
        Dir.glob("#{@static_sandbox_root}/#{build_dir}/**/#{@spec.name}/lib#{@spec.name}.a")
      else
        Dir.glob("#{@static_sandbox_root}/#{build_dir}/**/#{@spec.name}/lib#{@spec.name}.a")
      end
    end

    def vendored_libraries
      if @vendored_libraries
        @vendored_libraries
      end
      file_accessors = @file_accessors
      libs = file_accessors.flat_map(&:vendored_static_frameworks).map { |f| f + f.basename('.*') } || []
      libs += file_accessors.flat_map(&:vendored_static_libraries)
      @vendored_libraries = libs.compact.map(&:to_s)
      @vendored_libraries
    end

    def ios_build_options
      "ARCHS=\'#{ios_architectures.join(' ')}\'"
    end

    def ios_architectures
      archs = %w(x86_64 i386 arm64 armv7 armv7s)
      arch_for_sim = %w(x86_64 i386)
      archs -= arch_for_sim if @exclude_sim
      archs = archs - @exclude_archs.split(',')
      vendored_libraries.each do |library|
        archs = `lipo -info #{library}`.split & archs
      end
      archs
    end

    def xcodebuild(defines = '', args = '', build_dir = 'build', target = 'Pods-packager', project_root = @static_sandbox_root, config = @config)
      if defined?(Pod::DONT_CODESIGN)
        args = "#{args} CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO"
      end

      command = "xcodebuild #{defines} #{args} BUILD_DIR=#{build_dir} clean build -configuration #{config} -target #{target} -project #{project_root}/Pods.xcodeproj 2>&1"
      puts "#{command}"
      output = `#{command}`.lines.to_a

      if $?.exitstatus != 0
        puts UI::BuildFailedReport.report(command, output)

        # Note: We use `Process.exit` here because it fires a `SystemExit`
        # exception, which gives the caller a chance to clean up before the
        # process terminates.
        #
        # See http://ruby-doc.org/core-1.9.3/Process.html#method-c-exit
        Process.exit
      end
    end
  end
end
