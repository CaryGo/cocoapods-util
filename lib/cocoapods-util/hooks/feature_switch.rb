module Pod
    class_attr_accessor :is_prebuild_stage
end

module Pod    
    class Podfile
        module DSL
            def enable_framework_header_search_paths!(enable: false)
                DSL.enable_framework_header_search_paths = enable
            end

            private
            class_attr_accessor :enable_framework_header_search_paths
            enable_framework_header_search_paths = false
        end
    end
end