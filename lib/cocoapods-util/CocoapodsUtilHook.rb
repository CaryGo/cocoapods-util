module CocoapodsUtilHook
    Pod::HooksManager.register('cocoapods-util', :pre_install) do |installer_context, _|
        puts "pre_install"
        require_relative 'hooks/feature_switch'
        if Pod.is_prebuild_stage
            next
        end

        # [Check Environment]
        podfile = installer_context.podfile
        # podfile.target_definition_list.each do |target_definition|
        #     # next if target_definition.prebuild_framework_pod_names.empty?
        #     # if not target_definition.uses_frameworks?
        #     #     STDERR.puts "[!] Cocoapods-binary requires `use_frameworks!`".red
        #     #     exit
        #     # end
        # end

        require_relative 'hooks/prebuild_sandbox'

        # 读取update和repo_update参数
        update = nil
        repo_update = nil
        include ObjectSpace
        ObjectSpace.each_object(Pod::Installer) { |installer|
            update = installer.update
            repo_update = installer.repo_update
        }

        # switches setting
        Pod.is_prebuild_stage = true

        # make another custom sandbox
        standard_sandbox = installer_context.sandbox
        prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sandbox)

        # get the podfile for prebuild
        prebuild_podfile = Pod::Podfile.from_ruby(podfile.defined_in_file)
        
        # install
        lockfile = installer_context.lockfile
        binary_installer = Pod::Installer.new(prebuild_sandbox, prebuild_podfile, lockfile)

        binary_installer.update = update
        binary_installer.repo_update = repo_update
        binary_installer.install!

        # reset switches setting
        Pod.is_prebuild_stage = false
    end
    Pod::HooksManager.register('cocoapods-util', :pre_integrate) do |context, _|
        puts "pre_integrate"
    end
    Pod::HooksManager.register('cocoapods-util', :post_install) do |context, _|
        puts "post_install"
    end
    Pod::HooksManager.register('cocoapods-util', :post_integrate) do |context, _|
        puts "post_integrate"
    end
    Pod::HooksManager.register('cocoapods-util', :source_provider) do |context, _|
        puts "source_provider"
    end
end