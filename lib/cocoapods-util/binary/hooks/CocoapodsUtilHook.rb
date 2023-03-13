require_relative '../helper/podfile_options'

module CocoapodsUtilHook
    Pod::HooksManager.register('cocoapods-util', :pre_install) do |installer_context, _|
        require_relative 'pre_install'
        BinaryPrebuild::PreInstall.new(installer_context).run
    end

    Pod::HooksManager.register('cocoapods-util', :pre_integrate) do |context, _|
        
    end

    Pod::HooksManager.register('cocoapods-util', :post_install) do |context, _|
        require_relative 'post_install'
        BinaryPrebuild::PostInstall.new(context).run
    end

    Pod::HooksManager.register('cocoapods-util', :post_integrate) do |context, _|

    end
    
    Pod::HooksManager.register('cocoapods-util', :source_provider) do |context, _|

    end
end