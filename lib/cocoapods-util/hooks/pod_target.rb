module Pod
    class Target
      # @since 1.5.0
      class BuildSettings
        def enable_missing_framework_header(pt)
            Pod::Podfile::DSL.enable_targets.include? pt.name
        end

        def missing_framework_header_search_path(pt)
            return [] unless enable_missing_framework_header(pt)

            paths = []
            pt.file_accessors.each do |file_accessor|
                file_accessor.vendored_xcframeworks.map { |path| 
                    Xcode::XCFramework.new(file_accessor.spec.name, path) 
                }.each { |xcfwk| 
                    xcfwk.slices.each { |slice|
                        name = slice.path.basename
                        paths.push "${PODS_XCFRAMEWORKS_BUILD_DIR}/#{xcfwk.target_name}/#{name}/Headers" unless name.nil?
                    }
                }

                (file_accessor.vendored_frameworks - file_accessor.vendored_xcframeworks).each { |framework|
                    header_path = Pathname.new("#{framework}/Headers")
                    next unless header_path.exist?
                    paths.push "${PODS_ROOT}/#{header_path.relative_path_from(pt.sandbox.root)}"
                }
            end
            paths.uniq
        end

         # A subclass that generates build settings for a `PodTarget`
         class AggregateTargetSettings
            # @return [Array<String>]
            alias_method :old_raw_header_search_paths, :_raw_header_search_paths
            def _raw_header_search_paths
                header_search_paths = old_raw_header_search_paths
                header_search_paths.concat pod_targets.flat_map { |pt| missing_framework_header_search_path(pt) }
                header_search_paths.uniq
            end
         end

         # A subclass that generates build settings for a {PodTarget}
        class PodTargetSettings
            # @return [Array<String>]
            alias_method :old_raw_header_search_paths, :_raw_header_search_paths
            def _raw_header_search_paths
                header_search_paths = old_raw_header_search_paths
                # header_search_paths.concat missing_framework_header_search_path(target)
                header_search_paths.concat dependent_targets.flat_map { |pt| missing_framework_header_search_path(pt) } if target.should_build?
                header_search_paths.uniq
            end
         end
      end
    end
end