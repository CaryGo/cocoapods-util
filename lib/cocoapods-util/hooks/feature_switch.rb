module Pod
    class_attr_accessor :is_prebuild_stage
end

module Pod    
    class Podfile
        module DSL
            def self.enable_framework_header_keyword
                :enable_framework_header
            end

            def enable_all_framework_header!(enable: true)
                DSL.enable_all = enable
            end

            private
            class_attr_accessor :enable_all
            self.enable_all = false

            class_attr_accessor :enable_targets
            self.enable_targets = []

            # hook
            old_method = instance_method(:pod)
            define_method(:pod) do |name, *args|
                enable = DSL.enable_all
                options = args.last
                keyword = DSL.enable_framework_header_keyword
                if options.is_a?(Hash) && options[keyword] != nil 
                    enable = options.delete(keyword)
                    args.pop if options.empty?
                end
                DSL.enable_targets.push name if enable
                old_method.bind(self).(name, *args)
            end
        end
    end
end