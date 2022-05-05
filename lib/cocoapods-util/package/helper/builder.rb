require 'cocoapods-util/xcframework/xcramework_build.rb'
require 'cocoapods-util/package/helper/framework_builder.rb'
require 'cocoapods-util/package/helper/library_builder.rb'

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
      @exclude_sim = exclude_sim || @platform.name.to_s == 'osx'
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
      UI.puts("Building static #{@platform.name.to_s} library #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines) unless @exclude_sim

      create_library
    end

    def build_static_framework
      UI.puts("Building static #{@platform.name.to_s} framework #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines) unless @exclude_sim

      frameworks = generate_frameworks
      framework_paths = frameworks.map {|fwk| fwk.fwk_path }
      # merge framework
      if (1..2) === frameworks.count
        fwk = frameworks.first
        fwk_lib = "#{fwk.versions_path}/#{@spec.name}"
        if frameworks.count == 2
          other_fwk = frameworks.last
          other_fwk_lib = "#{other_fwk.versions_path}/#{@spec.name}"

          # check appletv archs
          if @platform.name.to_s == 'tvos'
            archs = `lipo -archs #{fwk_lib}`.split
            remove_archs = `lipo -archs #{other_fwk_lib}`.split & archs    
            `lipo -remove #{remove_archs.join(' -remove ')} #{other_fwk_lib} -output #{other_fwk_lib}` unless remove_archs.empty?
          end

          `lipo -create #{fwk_lib} #{other_fwk_lib} -output #{fwk_lib}`
        end
        `cp -a #{fwk.fwk_path} #{@platform.name.to_s}/`
      end
      # delete framework
      framework_paths.each { |path| FileUtils.rm_rf(File.dirname(path)) }
    end

    def build_static_xcframework
      UI.puts("Building static #{@platform.name.to_s} framework #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines) unless @exclude_sim

      frameworks = generate_frameworks
      framework_paths = frameworks.map {|fwk| fwk.fwk_path }

      # gemerate xcframework
      xcbuilder = XCFrameworkBuilder.new(
        @spec.name,
        @platform.name.to_s,
        true
      )
      xcbuilder.generate_xcframework(framework_paths)
      # delete framework
      framework_paths.each { |path| FileUtils.rm_rf(File.dirname(path)) }
    end

    def generate_frameworks
      frameworks = []
      os_names = ['build']
      os_names += ['build-sim'] unless @exclude_sim
      os_names.each do |os|
        frameworks << create_framework(os)
        framework_build_static_library(os)
        framework_copy_headers(os)
        framework_copy_license
        framework_copy_resources(os)
      end
      frameworks
    end

    def build_sim_libraries(defines)
      case @platform.name
      when :ios
        xcodebuild(defines, '-sdk iphonesimulator', 'build-sim')
      when :watchos
        xcodebuild(defines, '-sdk watchsimulator', 'build-sim')
      when :tvos
        xcodebuild(defines, '-sdk appletvsimulator', 'build-sim')
      end
    end

    def compile
      defines = ("" << @spec.consumer(@platform).compiler_flags.join(' '))

      if @platform.name == :ios
        options = ios_build_options
      end

      xcodebuild(defines, options)

      defines
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

    def expand_paths(path_specs)
      path_specs.map do |path_spec|
        Dir.glob(File.join(@source_dir, path_spec))
      end
    end

    def ios_architectures
      case @platform.name
      when :ios
        os_archs = ['arm64', 'armv7', 'armv7s']
        sim_archs = ['i386', 'x86_64']
      when :osx
        os_archs = ['arm64', 'x86_64']
        sim_archs = []
      when :watchos
        os_archs = ['armv7k', 'arm64_32']
        sim_archs = ['arm64', 'i386', 'x86_64']
      when :tvos
        os_archs = ['arm64']
        sim_archs = ['arm64', 'x86_64']
      end
      archs = os_archs
      archs += sim_archs unless @exclude_sim
      archs -= @exclude_archs.split(',')
      vendored_libraries.each do |library|
        archs = `lipo -info #{library}`.split & archs
      end
      archs
    end

    def os_build_name(build_root)
      build_name = "#{@config}"
      case build_root
      when 'build'
          case @platform.name
          when :ios
            build_name += "-iphoneos"
          when :watchos
            build_name += '-watchos'
          when :tvos
            build_name += '-appletvos'
          end
      else
          case @platform.name
          when :ios
            build_name += "-iphonesimulator"
          when :watchos
            build_name += '-watchsimulator'
          when :tvos
            build_name += '-appletvsimulator'
          end
      end
      build_name
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
