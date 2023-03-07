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

        def existed_target_names(name)
            exsited_framework_name_pairs.select {|pair| pair[0] == name }.map { |pair| pair[0]}
        end

        def exsited_framework_name_pairs
            return [] unless framework_search_path.exist?
            targets = framework_search_path.children().map do |framework_path|
                if framework_path.directory? && (not framework_path.children.empty?)
                    [framework_path.basename.to_s, framework_path]
                end
            end.reject(&:nil?).uniq
            targets
        end

        def framework_folder_path_for_target_name(name)
            exsited_framework_name_pairs.select {|pair| pair[0] == name }.map {|pair| pair[1] }.last
        end
    end
end