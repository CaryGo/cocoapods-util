module Pod    
    class Podfile
        module DSL
            def self.framework_header_keyword
                :framework_search_header
            end

            def self.binary_keyword
                :binary
            end
            
            def all_framework_search_header!(enable=true)
                options = {'all_framework_search_header': enable}
                BinaryPrebuild.config.dsl_config.merge!(options)
            end

            def all_binary!
                options = {'all_binary': true}
                BinaryPrebuild.config.dsl_config.merge!(options)
            end

            def config_cocoapods_util(options)
                BinaryPrebuild.config.dsl_config = options
                BinaryPrebuild.config.validate_dsl_config
            end

            # hook
            old_method = instance_method(:pod)
            define_method(:pod) do |name, *args|
                framework_header_enable = BinaryPrebuild.config.all_framework_header_enable?
                binary_enable = BinaryPrebuild.config.all_binary_enable?
                options = args.last
                if options.is_a?(Hash) && options[DSL.framework_header_keyword] != nil
                    framework_header_enable = options.delete(DSL.framework_header_keyword)
                    args.pop if options.empty?
                end
                if options.is_a?(Hash) && options[DSL.binary_keyword] != nil
                    binary_enable = options.delete(DSL.binary_keyword)
                    args.pop if options.empty?
                end
                target_name = name.to_s.gsub(/\/.*$/, '')
                BinaryPrebuild.config.add_framework_header_target(target_name) if framework_header_enable
                BinaryPrebuild.config.add_binary_target(target_name) if binary_enable
                old_method.bind(self).(name, *args)
            end
        end
    end
end