require_relative 'pre_install'
require_relative 'post_install'

module CocoapodsUtilHook
    Pod::HooksManager.register('cocoapods-util', :pre_install) do |installer_context, _|
        BinaryPrebuild::PreInstall.new(installer_context).run
    end

    Pod::HooksManager.register('cocoapods-util', :pre_integrate) do |context, _|
        
    end

    Pod::HooksManager.register('cocoapods-util', :post_install) do |context, _|
        BinaryPrebuild::PostInstall.new(context).run
    end

    Pod::HooksManager.register('cocoapods-util', :post_integrate) do |context, _|

    end
    
    Pod::HooksManager.register('cocoapods-util', :source_provider) do |context, _|

    end
end