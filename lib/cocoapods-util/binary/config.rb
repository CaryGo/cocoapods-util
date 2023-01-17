module BinaryPrebuild
    def self.config
        BinaryPrebuild::Config.instance
    end

    class Config 
        attr_accessor :enable_all, :enable_targets
    
        def initialize()
            @enable_all = false
            @enable_targets = []
        end
    
        def self.instance
          @instance ||= new()
        end

        def add_enable_target(name)
            @enable_targets.push name
            @enable_targets.uniq!
        end
    end
end