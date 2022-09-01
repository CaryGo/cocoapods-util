module Pod
  class Command
    class Util < Command
      class Package < Util
        private

        def build_static_sandbox
          static_sandbox_root = Pathname.new(config.sandbox_root)
          Sandbox.new(static_sandbox_root)
        end

        def install_pod(platform_name, sandbox)
          podfile = podfile_from_spec(
            @path,
            @spec.name,
            platform_name,
            @spec.deployment_target(platform_name),
            @subspecs,
            @spec_sources,
            @use_modular_headers,
            @dependency_config
          )

          static_installer = Installer.new(sandbox, podfile)
          static_installer.install!

          unless static_installer.nil?
            # default build settings
            default_build_settings = Hash.new
            default_build_settings["CLANG_MODULES_AUTOLINK"] = "NO"
            default_build_settings["GCC_GENERATE_DEBUGGING_SYMBOLS"] = "YES" # 生成Debug编译信息
            default_build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64" unless @xcframework && self.match_pod_version?('~> 1.11') # 非xcframework排除ios simulator 64位架构
            default_build_settings["EXCLUDED_ARCHS[sdk=appletvsimulator*]"] = "arm64" unless @xcframework && self.match_pod_version?('~> 1.11') # 非xcframework排除tvos simulator 64位架构
            default_build_settings["BUILD_LIBRARY_FOR_DISTRIBUTION"] = "YES" # 编译swift生成swiftinterface文件
            
            # merge user setting
            default_build_settings.merge!(@build_settings) unless @build_settings.empty?

            static_installer.pods_project.targets.each do |target|
              target.build_configurations.each do |config|
                default_build_settings.each { |key, value| config.build_settings[key.to_s] = value.to_s }
              end
            end
            static_installer.pods_project.save
          end

          static_installer
        end

        def podfile_from_spec(path, spec_name, platform_name, deployment_target, subspecs, sources, use_modular_headers, dependency_config)
          options = {}
          if path
            if @local
              options[:path] = path
            else
              options[:podspec] = path
            end
          end
          options[:subspecs] = subspecs if subspecs
          Pod::Podfile.new do
            sources.each { |s| source s }
            platform(platform_name, deployment_target)
            pod(spec_name, options) unless dependency_config.keys.include?(spec_name)
            
            dependency_config.each do |name, config|
              dependency_options = {}
              config.each do |key, value|
                dependency_options[key.to_sym] = value
              end
              pod(name, dependency_options)
            end

            use_modular_headers! if use_modular_headers
            install!('cocoapods',
                    :integrate_targets => false,
                    :deterministic_uuids => false)

            target('packager') do
              inherit! :complete
            end
          end
        end

        def binary_only?(spec)
          deps = spec.dependencies.map { |dep| spec_with_name(dep.name) }
          [spec, *deps].each do |specification|
            %w(vendored_frameworks vendored_libraries).each do |attrib|
              if specification.attributes_hash[attrib]
                return true
              end
            end
          end

          false
        end

        def spec_with_name(name)
          return if name.nil?

          set = Pod::Config.instance.sources_manager.search(Dependency.new(name))
          return nil if set.nil?

          set.specification.root
        end

        def spec_with_path(path)
          return if path.nil? || !Pathname.new(path).exist?

          @path = Pathname.new(path).expand_path

          if @path.directory?
            help! @path + ': is a directory.'
            return
          end

          unless ['.podspec', '.json'].include? @path.extname
            help! @path + ': is not a podspec.'
            return
          end

          Specification.from_file(@path)
        end

        def match_pod_version?(*version)
          Gem::Dependency.new('', *version).match?('', Pod::VERSION)
        end
      end
    end
  end
end
