module BinaryPrebuild
    def self.config
        BinaryPrebuild::Config.instance
    end

    class Config 
        attr_accessor :dsl_config

        APPLICABLE_DSL_CONFIG = [
            :all_binary,
            :binary_dir,
            :dev_pods_enabled,
            :xcconfig_replace_path,
        ].freeze

        def initialize()
            @dsl_config = {}
        end
    
        def self.instance
          @instance ||= new()
        end

        def validate_dsl_config
            inapplicable_options = @dsl_config.keys - APPLICABLE_DSL_CONFIG
            return if inapplicable_options.empty?
            
            message = <<~HEREDOC
              [WARNING] The following options (in `config_cocoapods_util`) are not correct: #{inapplicable_options}.
              Available options: #{APPLICABLE_DSL_CONFIG}.
            HEREDOC
      
            Pod::UI.puts message.yellow
        end

        def all_binary_enable?
            @dsl_config[:all_binary] || false
        end

        def dev_pods_enabled?
            @dsl_config[:dev_pods_enabled] || false
        end

        def binary_dir
            @dsl_config[:binary_dir] || '_Prebuild'
        end

        def xcconfig_replace_path
            @dsl_config[:xcconfig_replace_path] || "cocoapods-util-binary"
        end
    end
end