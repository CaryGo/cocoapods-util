module Pod
    class Target
      # @since 1.5.0
      class BuildSettings
        # missing framework header search paths
        def missing_framework_header_search_path(pt)
            return [] unless BinaryPrebuild.config.enable_targets.include? pt.name

            paths = []
            pt.file_accessors.each do |file_accessor|
                # xcframeworks
                greater_than_or_equal_to_1_10_0 = Gem::Version.new(Pod::VERSION) >= Gem::Version.new('1.10.0')
                greater_than_or_equal_to_1_11_0 = Gem::Version.new(Pod::VERSION) >= Gem::Version.new('1.11.0')
                file_accessor.vendored_xcframeworks.map { |path| 
                    if greater_than_or_equal_to_1_11_0
                        Xcode::XCFramework.new(file_accessor.spec.name, path)
                    else
                        Xcode::XCFramework.new(path)
                    end
                }.each { |xcfwk| 
                    xcfwk.slices.each { |slice|
                        fwk_name = slice.path.basename
                        if greater_than_or_equal_to_1_11_0
                            paths.push "${PODS_XCFRAMEWORKS_BUILD_DIR}/#{xcfwk.target_name}/#{fwk_name}/Headers"
                        elsif greater_than_or_equal_to_1_10_0
                            paths.push "${PODS_XCFRAMEWORKS_BUILD_DIR}/#{fwk_name.to_s.gsub(/\.framework$/, '')}/#{fwk_name}/Headers"
                        else
                            paths.push "${PODS_CONFIGURATION_BUILD_DIR}/#{fwk_name}/Headers"
                        end
                    }
                }
                # Cocoapods 1.9.x bugs
                if Gem::Version.new(Pod::VERSION) < Gem::Version.new('1.10.0')
                    file_accessor.vendored_xcframeworks.each { |path| 
                        Dir.glob("#{path.to_s}/**/*.framework").each do |fwk_path|
                            header_path = Pathname.new("#{fwk_path}/Headers")
                            next unless header_path.exist?
                            paths.push "${PODS_ROOT}/#{header_path.relative_path_from(pt.sandbox.root)}"
                        end 
                    }
                end

                # frameworks
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
                header_search_paths.concat dependent_targets.flat_map { |pt| missing_framework_header_search_path(pt) } if target.should_build?
                header_search_paths.uniq
            end
         end
      end
    end
end