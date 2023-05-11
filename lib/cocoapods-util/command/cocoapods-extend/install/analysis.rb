module Pod
    class PodAnalysis
        def initialize(name, showmore)
            @name = name
            @showmore = showmore
        end

        def run
            config = Pod::Config.instance
            @lockfile = config.lockfile
            @installer = Pod::Installer.new(config.sandbox, config.podfile, config.lockfile)
            @installer.sandbox.prepare # sandbox prepare
            @installer.resolve_dependencies # 解析依赖
            
            all_pods = all_installed_pods!
            # 忽略大小写检查name
            match_pods = all_pods.select { |pod_name| @name && pod_name.downcase == @name.downcase }
            @name = match_pods.first if match_pods.size == 1

            # 解析所有依赖
            all_pod_analysis!

            if @name && all_pods.include?(@name)
                check_podinfo(@name)
            else
                all_pods.each_index do |index|
                    check_podinfo(all_pods[index], index+1)
                end
            end
        end

        def check_podinfo(name, index=1)
            UI.puts "#{index}).".red " #{name} ".green "(#{pods_tag![name]})".yellow
            
            # repo spec
            repo_name = pod_spec_repos![name]
            UI.puts "   - SPEC REPO: ".yellow "#{repo_name}".green unless repo_name.nil?
            
            # external sources
            external_sources = @lockfile.internal_data['EXTERNAL SOURCES']
            unless external_sources.nil?
              external_dict = external_sources[name]
              UI.puts "   - EXTERNAL SOURCES: ".yellow unless external_dict.nil?
              external_dict.each { |key, value| UI.puts "     - #{key}: ".yellow "#{value}".green } unless external_dict.nil?
            end

            show_moreinfo(name) if @showmore
        end

        def show_moreinfo(name)
            # checkout options
            checkout_options = @lockfile.internal_data['CHECKOUT OPTIONS']
            unless checkout_options.nil?
              checkout_dict = checkout_options[name]
              UI.puts "   - CHECKOUT OPTIONS: ".yellow unless checkout_dict.nil?
              checkout_dict.each { |key, value| UI.puts "     - #{key}: ".yellow "#{value}".green } unless checkout_dict.nil?
            end

            targets = @targets_hash[name]
            dependent_targets = @dependencies_hash[name]

            # subspecs
            subspecs = targets.flat_map do |target| 
                target.specs.reject { |spec| spec == spec.root }.map(&:name)
            end.uniq

            # dependencies
            dependencies = dependent_targets.map(&:pod_name).uniq
            
            # parents
            parents = @dependencies_hash.map do |pod_name, dependent_targets|
                next if pod_name == name
                pod_name if dependent_targets.map(&:pod_name).uniq.include?(name)
            end.reject(&:nil?)

            UI.puts "   - SUBSPECS: ".yellow "#{subspecs.uniq.join('、')}".green unless subspecs.empty?
            UI.puts "   - DEPENDENCIES: ".yellow "#{dependencies.uniq.join('、')}".green unless dependencies.empty?
            UI.puts "   - DEPENDS ON IT: ".yellow "#{parents.uniq.join('、')}".green unless parents.empty?
        end

        def all_pod_analysis!
            # 递归查找依赖
            def recursion_dependent_targets(target)
                target.dependent_targets.flat_map {|t|
                    targets = [t]
                    targets += recursion_dependent_targets(t) if target.dependent_targets.size > 0
                    targets
                }.reject(&:nil?)
            end

            def analysis!(pod_name)
                #  获取依赖
                targets = []
                dependent_targets = @installer.pod_targets.flat_map {|target|
                    match_pod = target.pod_name.to_s == pod_name
                    targets << target if match_pod
                    recursion_dependent_targets(target) if match_pod
                }.reject(&:nil?).uniq

                [targets, dependent_targets]
            end
            
            @targets_hash = {}
            @dependencies_hash = {}
            all_installed_pods!.each do |pod_name|
                analysis = analysis!(pod_name)
                @targets_hash[pod_name] = analysis[0]
                @dependencies_hash[pod_name] = analysis[1]
            end
        end

        def dependent_targets!(pod_name)
            
        end

        def all_installed_pods!
            @installed_pods ||= @lockfile.internal_data["SPEC CHECKSUMS"].flat_map { |k, _| k }
        end

        def pods_tag!
            @tags ||= begin
                tags = {}
                all_installed_pods!.each do |name|
                    target = @targets_hash[name].first
                    next if target.nil?
                    spec = target.specs.first
                    next if spec.nil?
                    tags[name] = spec.version.to_s
                end
                tags
            end
        end

        def pod_spec_repos!
            @repos ||= begin
                repos = {}
                @lockfile.internal_data["SPEC REPOS"].each do |key, value|
                    value.each {|item| repos[item] = key } if value.is_a?(Array)
                end
                repos
            end
        end
    end
end