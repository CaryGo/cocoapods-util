module Pod    
    class Podfile
        module DSL
            def config_cocoapods_util(options)
                BinaryPrebuild.config.dsl_config = options
                BinaryPrebuild.config.validate_dsl_config
            end
        end
    end
end