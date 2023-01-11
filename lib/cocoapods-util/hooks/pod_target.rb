module Pod
    class PodTarget < Target
        def enable_framework_header_search_path
            Pod::Podfile::DSL.enable_targets.include? self.name
        end

        # 获取file_accessors中vendored_frameworks的header_search_paths
        def accessors_framework_header_paths(target)
            header_search_paths = []
            target.file_accessors.each do |file_accessor|
                file_accessor.vendored_frameworks.select do |path| 
                    header_dir_path = Pathname.new("#{path}/Headers")
                    next unless header_dir_path.exist?
                    relative_path_to_sandbox = header_dir_path.relative_path_from(target.sandbox.root)
                    header_search_paths.push "${PODS_ROOT}/#{relative_path_to_sandbox}"
                end
            end
            header_search_paths
        end

        # 获取target依赖子target的framework_header_search_paths，解决使用framework时无法使用`""`引用头文件的问题
        def framework_header_search_path(configuration: nil, from_aggregate_target: false)
            # switch enable
            return [] unless self.enable_framework_header_search_path

            framework_header_search_paths = []
            # aggregate_target
            if from_aggregate_target
                framework_header_search_paths.concat(accessors_framework_header_paths(self)) 
            end
            return framework_header_search_paths unless should_build? 
            
            # should_build 
            dependent_targets = recursive_dependent_targets(:configuration => configuration)
            dependent_targets.each do |target|
                framework_header_search_paths.concat(accessors_framework_header_paths(target))
            end
            framework_header_search_paths
        end
    end
end

module Pod
    class Target
      # @since 1.5.0
      class BuildSettings
         # A subclass that generates build settings for a `PodTarget`
         class AggregateTargetSettings
            # @return [Array<String>]
            alias_method :old_raw_header_search_paths, :_raw_header_search_paths
            def _raw_header_search_paths
                header_search_paths = old_raw_header_search_paths
                target.pod_targets.each do |t|
                    header_search_paths.concat t.framework_header_search_path :configuration => @configuration, :from_aggregate_target => true
                end
                header_search_paths.uniq
            end
         end

         # A subclass that generates build settings for a {PodTarget}
        class PodTargetSettings
            # @return [Array<String>]
            alias_method :old_raw_header_search_paths, :_raw_header_search_paths
            def _raw_header_search_paths
                header_search_paths = old_raw_header_search_paths
                header_search_paths.concat target.framework_header_search_path :configuration => @configuration
                header_search_paths.uniq
            end
         end
      end
    end
end