module Pod
  class Command
    class Util < Command
      class Package < Util
        private

        def build_static_sandbox(dynamic)
          static_sandbox_root = if dynamic
                                  Pathname.new(config.sandbox_root + '/Static')
                                else
                                  Pathname.new(config.sandbox_root)
                                end
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
            static_installer.pods_project.targets.each do |target|
              target.build_configurations.each do |config|
                config.build_settings['CLANG_MODULES_AUTOLINK'] = 'NO'
                config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'NO'
                config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
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
            pod(spec_name, options)

            dependency_config.each do |name, config|
              options = {}
              config.each do |key, value|
                options[:"#{key}"] = value
              end
              pod(name, options)
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
      end
    end
  end
end
