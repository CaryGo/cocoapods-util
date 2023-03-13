module BinaryPrebuild
    class PreInstall
        def initialize(installer_context)
            @installer_context = installer_context
        end

        def run
            # [Check Environment]
            podfile = @installer_context.podfile
            podfile.target_definition_list.each do |target_definition|
                if not target_definition.uses_frameworks?
                    STDERR.puts "[!] Cocoapods-binary requires `use_frameworks!`".red
                    exit
                end
            end

            require_relative '../targets/pod_target'
            require_relative '../Intergation'
        end
    end
end