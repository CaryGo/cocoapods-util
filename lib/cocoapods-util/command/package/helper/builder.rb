module Pod
  class Builder
    def initialize(platform, static_installer, source_dir, static_sandbox_root, public_headers_root, spec, config, exclude_sim, framework_contains_resources, verbose)
      @platform = platform
      @static_installer = static_installer
      @source_dir = source_dir
      @static_sandbox_root = static_sandbox_root
      @public_headers_root = public_headers_root
      @spec = spec
      @config = config
      @exclude_sim = exclude_sim || @platform.name.to_s == 'osx'
      @framework_contains_resources = framework_contains_resources
      @verbose = verbose

      @file_accessors = @static_installer.pod_targets.select { |t| t.pod_name == @spec.name }.flat_map(&:file_accessors)
    end

    def build(package_type)
      require_relative 'framework_builder.rb'
      require_relative 'library_builder.rb'

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
      UI.puts("Building #{@platform.name.to_s} static library #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines) unless @exclude_sim

      create_library
      UI.puts("Building #{@platform.name.to_s} static library #{@spec} with configuration #{@config} success")
    end

    def build_static_framework
      UI.puts("Building #{@platform.name.to_s} static framework #{@spec} with configuration #{@config}")

      defines = compile
      build_sim_libraries(defines) unless @exclude_sim

      frameworks = generate_frameworks
      combine_frameworks(frameworks)
      
      # delete framework
      framework_paths = frameworks.map {|fwk| fwk.fwk_path }
      framework_paths.each { |path| FileUtils.rm_rf(File.dirname(path)) }

      UI.puts("Building #{@platform.name.to_s} static framework #{@spec} with configuration #{@config} success")
    end

    def build_static_xcframework
      require_relative '../../xcframework/xcframework_build.rb'
      UI.puts("Building #{@platform.name.to_s} static framework #{@spec} with configuration #{@config}")

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

    def build_sim_libraries(defines)
      options = build_options
      case @platform.name
      when :ios
        options << ' -sdk iphonesimulator'
      when :watchos
        options << ' -sdk watchsimulator'
      when :tvos
        options << ' -sdk appletvsimulator'
      else
        return
      end
      xcodebuild(defines, options, 'build-sim')
    end

    def compile
      defines = ("" << @spec.consumer(@platform).compiler_flags.join(' '))

      options = build_options
      case @platform.name
      when :ios
        options << ' -sdk iphoneos'
      when :osx
        options << ' -sdk macosx'
      when :watchos
        options << ' -sdk watchos'
      when :tvos
        options << ' -sdk appletvos'
      end
      xcodebuild(defines, options)

      defines
    end

    def build_options
      vendored_archs = []
      vendored_libraries.each do |library|
        vendored_archs = vendored_archs | `lipo -archs #{library}`.split
        UI.puts "library at #{library}, archs: #{vendored_archs}" if @verbose
      end
      options = ("ARCHS=\'#{vendored_archs.join(' ')}\'" unless vendored_archs.empty?) || ""
      options
    end

    def static_libs_in_sandbox(build_dir = 'build')
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

    def expand_paths(path_specs)
      path_specs.map do |path_spec|
        Dir.glob(File.join(@source_dir, path_spec))
      end
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

      command = "xcodebuild #{defines} #{args} BUILD_DIR=#{build_dir} clean build -configuration #{config} -target #{target} -project #{project_root}/Pods.xcodeproj 2>&1".gsub!(/\s+/, ' ')
      UI.puts "#{command}" if @verbose
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
