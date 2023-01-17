module Pod    
    class Podfile
        module DSL
            def self.enable_framework_header_keyword
                :enable_framework_header
            end

            def enable_all_framework_header!(enable: true)
                BinaryPrebuild.config.enable_all = enable
            end

            # hook
            old_method = instance_method(:pod)
            define_method(:pod) do |name, *args|
                enable = BinaryPrebuild.config.enable_all
                options = args.last
                keyword = DSL.enable_framework_header_keyword
                if options.is_a?(Hash) && options[keyword] != nil
                    enable = options.delete(keyword)
                    args.pop if options.empty?
                end
                BinaryPrebuild.config.add_enable_target name.to_s.gsub(/\/.*$/, '') if enable
                old_method.bind(self).(name, *args)
            end
        end
    end
end