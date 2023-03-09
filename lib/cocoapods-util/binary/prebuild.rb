module BinaryPrebuild
    class Sandbox
        def initialize(path)
            @sandbox_path = path
        end
    
        def self.from_sandbox(sandbox)
            root = sandbox.root
            search_path = BinaryPrebuild.config.framework_search_path
            if !search_path.nil? && !search_path.empty?
                path = File.expand_path(root + search_path)
                if File.exist? path
                    return Sandbox.new(path)
                end
            end
        end

        def framework_search_path
            @framework_file_path ||= Pathname.new(@sandbox_path)
        end

        def target_paths
            return [] unless framework_search_path.exist?
            @targets ||= framework_search_path.children().map do |target_path|
                if target_path.directory? && (not target_path.children.empty?)
                    target_path
                end
            end.reject(&:nil?).uniq
            @targets
        end

        def existed_target_names(name)
            target_paths.select { |pair| "#{pair.basename}" == "#{name}" }.map { |pair| pair.basename }
        end

        def framework_folder_path_for_target_name(name)
            target_paths.select { |pair| pair.basename == name }.last
        end

        def prebuild_vendored_frameworks(name)
            target_path = target_paths.select { |pair| "#{pair.basename}" == "#{name}" }.last
            return [] if target_path.nil?

            configuration_enable = target_path.children().select { |path| "#{path.basename}" == 'Debug' || "#{path.basename}" == 'Release' }.count == 2
            if configuration_enable
                xcconfig_replace_path = BinaryPrebuild.config.xcconfig_replace_path
                ["#{xcconfig_replace_path}-Release/*.{framework,xcframework}"]
            else
                ["*.{framework,xcframework}"]
            end
        end

        def prebuild_bundles(name)
            target_path = target_paths.select { |pair| "#{pair.basename}" == "#{name}" }.last
            return [] if target_path.nil?

            configuration_enable = target_path.children().select { |path| "#{path.basename}" == 'Debug' || "#{path.basename}" == 'Release' }.count == 2
            if configuration_enable
                xcconfig_replace_path = BinaryPrebuild.config.xcconfig_replace_path
                ["#{xcconfig_replace_path}-Release/*.bundle"]
            else
                ["*.bundle"]
            end
        end
    end
end