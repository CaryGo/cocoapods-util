module CocoapodsUtilHook
    Pod::HooksManager.register('cocoapods-util', :pre_install) do |context, _|
        puts "pre_install"
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
  