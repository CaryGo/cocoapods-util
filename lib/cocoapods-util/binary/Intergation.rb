require_relative 'helper/podfile_options'
require_relative 'helper/names'
require_relative 'helper/target_checker'


# NOTE:
# This file will only be loaded on normal pod install step
# so there's no need to check is_prebuild_stage



# Provide a special "download" process for prebuilded pods.
#
# As the frameworks is already exsited in local folder. We
# just create a symlink to the original target folder.
#
module Pod
    class Installer
        class PodSourceInstaller

            def install_for_prebuild!(standard_sanbox)
            #     return if standard_sanbox.local? self.name

                # make a symlink to target folder
                prebuild_sandbox = BinaryPrebuild::Sandbox.from_sandbox(self.sandbox)
                return if prebuild_sandbox.nil?
                # if spec used in multiple platforms, it may return multiple paths
                target_names = prebuild_sandbox.existed_target_names(self.name)
                
                def walk(path, &action)
                    return unless path.exist?
                    path.children.each do |child|
                        result = action.call(child, &action)
                        if child.directory?
                            walk(child, &action) if result
                        end
                    end
                end
                def make_link(source, target)
                    source = Pathname.new(source)
                    target = Pathname.new(target)
                    target.parent.mkpath unless target.parent.exist?
                    relative_source = source.relative_path_from(target.parent)
                    FileUtils.ln_sf(relative_source, target)
                end
                def mirror_with_symlink(source, basefolder, target_folder)
                    relative_path = source.relative_path_from(basefolder)
                    if relative_path.to_s =~ /^(Debug|Release)\/.*/
                        new_relative_path = relative_path.to_s.gsub!(/^(Debug|Release)/) { |match| "#{BinaryPrebuild.config.xcconfig_replace_path}-#{match}" }
                        target = Pathname.new("#{target_folder}/#{new_relative_path}")
                        make_link(source, target)
                    else
                        target = Pathname.new("#{target_folder}/#{relative_path}")
                        make_link(source, target)
                    end
                end
                
                target_names.each do |name|

                    # symbol link copy all substructure
                    real_file_folder = prebuild_sandbox.framework_folder_path_for_target_name(name)
                    
                    # If have only one platform, just place int the root folder of this pod.
                    # If have multiple paths, we use a sperated folder to store different
                    # platform frameworks. e.g. AFNetworking/AFNetworking-iOS/AFNetworking.framework
                    
                    target_folder = standard_sanbox.pod_dir(self.name) +  "_Prebuild"
                    target_folder.rmtree if target_folder.exist?
                    target_folder.mkpath


                    walk(real_file_folder) do |child|
                        source = child
                        # only make symlink to file and `.framework` folder
                        if child.directory? and [".framework", ".xcframework", ".bundle", ".dSYM"].include? child.extname
                            mirror_with_symlink(source, real_file_folder, target_folder)
                            next false  # return false means don't go deeper
                        elsif child.file?
                            mirror_with_symlink(source, real_file_folder, target_folder)
                            next true
                        else
                            next true
                        end
                    end
                end # of for each 

            end # of method

        end
    end
end


# Let cocoapods use the prebuild framework files in install process.
#
# the code only effect the second pod install process.
#
module Pod
    class Installer
        # Modify specification to use only the prebuild framework after analyzing
        old_method2 = instance_method(:resolve_dependencies)
        define_method(:resolve_dependencies) do
            # call original
            old_method2.bind(self).()
            # ...
            # ...
            # ...
            # after finishing the very complex orginal function

            # check the pods
            # Although we have did it in prebuild stage, it's not sufficient.
            # Same pod may appear in another target in form of source code.
            # Prebuild.check_one_pod_should_have_only_one_target(self.prebuild_pod_targets)
            # self.validate_every_pod_only_have_one_form

            # prepare
            cache = []

            def add_vendered_framework(spec, platform, added_framework_file_path)
                if spec.attributes_hash[platform] == nil
                    spec.attributes_hash[platform] = {}
                end
                vendored_frameworks = spec.attributes_hash[platform]["vendored_frameworks"] || []
                vendored_frameworks = [vendored_frameworks] if vendored_frameworks.kind_of?(String)
                vendored_frameworks += [added_framework_file_path]
                spec.attributes_hash[platform]["vendored_frameworks"] = vendored_frameworks
            end
            def empty_source_files(spec)
                spec.attributes_hash["source_files"] = []
                spec.attributes_hash["public_header_files"] = []
                spec.attributes_hash["private_header_files"] = []
                ["ios", "watchos", "tvos", "osx"].each do |plat|
                    if spec.attributes_hash[plat] != nil
                        spec.attributes_hash[plat]["source_files"] = []
                        spec.attributes_hash[plat]["public_header_files"] = []
                        spec.attributes_hash[plat]["private_header_files"] = []
                    end
                end
            end

            prebuild_sandbox = BinaryPrebuild::Sandbox.from_sandbox(self.sandbox)
            return if prebuild_sandbox.nil?

            specs = self.analysis_result.specifications
            prebuilt_specs = (specs.select do |spec|
                # rmtree
                target_prebuild_files = self.sandbox.root + spec.root.name + "_Prebuild"
                target_prebuild_files.rmtree if target_prebuild_files.exist?

                target_names = prebuild_sandbox.existed_target_names(spec.root.name)
                BinaryPrebuild.config.binary_enable?(spec.root.name) && target_names.count > 0
            end)

            prebuilt_specs.each do |spec|

                # Use the prebuild framworks as vendered frameworks
                # get_corresponding_targets
                targets = Pod.fast_get_targets_for_pod_name(spec.root.name, self.pod_targets, cache)
                targets.each do |target|
                    # the framework_file_path rule is decided when `install_for_prebuild`,
                    # as to compitable with older version and be less wordy.
                    # framework_file_path = target.framework_name
                    # framework_file_path = target.name + "/" + framework_file_path if targets.count > 1
                    
                    break if spec.name.to_s =~ /[^\/]*\/[^\/]*/
                    
                    prebuild_sandbox.prebuild_vendored_frameworks(spec.root.name).each do |frame_file_path|
                        framework_file_path = "_Prebuild/" + frame_file_path
                        add_vendered_framework(spec, target.platform.name.to_s, framework_file_path)
                    end
                end
                # Clean the source files
                # we just add the prebuilt framework to specific platform and set no source files 
                # for all platform, so it doesn't support the sence that 'a pod perbuild for one
                # platform and not for another platform.'
                empty_source_files(spec)

                # to remove the resurce bundle target. 
                # When specify the "resource_bundles" in podspec, xcode will generate a bundle 
                # target after pod install. But the bundle have already built when the prebuit
                # phase and saved in the framework folder. We will treat it as a normal resource
                # file.
                # https://github.com/leavez/cocoapods-binary/issues/29
                if spec.attributes_hash["resource_bundles"]
                    # bundle_names = spec.attributes_hash["resource_bundles"].keys
                    spec.attributes_hash["resource_bundles"] = nil 
                    spec.attributes_hash["resources"] ||= []
                    resources = spec.attributes_hash["resources"] || []
                    resources = [resources] if resources.kind_of?(String)
                    spec.attributes_hash["resources"] = resources
                    # spec.attributes_hash["resources"] += bundle_names.map{|n| n+".bundle"}
                    prebuild_bundles = prebuild_sandbox.prebuild_bundles(spec.root.name).each.map do |bundle_path|
                        "_Prebuild/" + bundle_path
                    end
                    spec.attributes_hash["resources"] += prebuild_bundles
                end

                # to avoid the warning of missing license
                spec.attributes_hash["license"] = {}
                spec.attributes_hash["preserve_paths"] = "**/*"

            end

        end


        # Override the download step to skip download and prepare file in target folder
        old_method = instance_method(:install_source_of_pod)
        define_method(:install_source_of_pod) do |pod_name|

            # copy from original
            pod_installer = create_pod_installer(pod_name)
            # \copy from original

             # copy from original
             pod_installer.install!
             # \copy from original

            if BinaryPrebuild.config.binary_enable? pod_name
                pod_installer.install_for_prebuild!(self.sandbox)
            end

            # copy from original
            @installed_specs.concat(pod_installer.specs_by_platform.values.flatten.uniq)
            # \copy from original
        end

        alias_method :old_create_pod_installer, :create_pod_installer
        def create_pod_installer(pod_name)
            pod_installer = old_create_pod_installer(pod_name)

            pods_to_install = sandbox_state.added | sandbox_state.changed
            unless pods_to_install.include?(pod_name)
                if BinaryPrebuild.config.binary_enable? pod_name
                    pod_installer.install_for_prebuild!(self.sandbox)
                end
            end
            pod_installer
        end
    end
end

# A fix in embeded frameworks script.
#
# The framework file in pod target folder is a symblink. The EmbedFrameworksScript use `readlink`
# to read the read path. As the symlink is a relative symlink, readlink cannot handle it well. So 
# we override the `readlink` to a fixed version.
#
module Pod
    module Generator
        class EmbedFrameworksScript

            old_method = instance_method(:script)
            define_method(:script) do

                script = old_method.bind(self).()
                patch = <<-SH.strip_heredoc
                    #!/bin/sh
                
                    # ---- this is added by cocoapods-binary ---
                    # Readlink cannot handle relative symlink well, so we override it to a new one
                    # If the path isn't an absolute path, we add a realtive prefix.
                    old_read_link=`which readlink`
                    readlink () {
                        path=`$old_read_link "$1"`;
                        if [ $(echo "$path" | cut -c 1-1) = '/' ]; then
                            echo $path;
                        else
                            echo "`dirname $1`/$path";
                        fi
                    }
                    # --- 
                SH

                # patch the rsync for copy dSYM symlink
                script = script.gsub "rsync --delete", "rsync --copy-links --delete"
                
                patch + script
            end
        end
    end
end

module Pod
    module Generator
      class CopyXCFrameworksScript

        alias_method :old_install_xcframework_args, :install_xcframework_args
        def install_xcframework_args(xcframework, slices)
            args = old_install_xcframework_args(xcframework, slices)
            if BinaryPrebuild.config.binary_enable? xcframework.target_name
                xcconfig_replace_path = BinaryPrebuild.config.xcconfig_replace_path
                args.gsub!(/#{xcconfig_replace_path}-(Debug|Release)/, "#{xcconfig_replace_path}-${CONFIGURATION}")
            end
            args
          end
      end
    end
end

module Pod
    module Generator
      class CopyResourcesScript

        alias_method :old_script, :script
        def script
            script = old_script
            xcconfig_replace_path = BinaryPrebuild.config.xcconfig_replace_path
            script.gsub!(/#{xcconfig_replace_path}-(Debug|Release)/, "#{xcconfig_replace_path}-${CONFIGURATION}")
            script
        end
      end
    end
end