module BinaryPrebuild
    def self.config
        BinaryPrebuild::Config.instance
    end

    class Config 
        attr_accessor :dsl_config

        APPLICABLE_DSL_CONFIG = [
            :all_framework_search_header,
            :all_binary,
            :dev_pods_enabled,
            :framework_search_path,
            :xcconfig_replace_path,
        ].freeze

        def initialize()
            @dsl_config = {}

            @framework_header_targets = []
            @binary_targets = []
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

        def add_framework_header_target(name)
            @framework_header_targets.push name
            @framework_header_targets.uniq!
        end

        def add_binary_target(name)
            @binary_targets.push name
            @binary_targets.uniq!
        end

        def framework_header_enable?(name)
            @framework_header_targets.include? name
        end

        def all_framework_header_enable?
            @dsl_config[:all_framework_search_header] || false
        end

        def binary_enable?(name)
            @binary_targets.include?(name)
        end

        def all_binary_enable?
            @dsl_config[:all_binary] || false
        end

        def dev_pods_enabled?
            @dsl_config[:dev_pods_enabled] || false
        end

        def framework_search_path
            @dsl_config[:framework_search_path]
        end

        def xcconfig_replace_path
            @dsl_config[:xcconfig_replace_path] || "cocoapods-util-binary"
        end
    end
end