module Pod
    class Command
        class Util < Command
            class Unique < Util
                self.summary = '对Xcode的工程文件做去重处理。'
                self.description = <<-DESC
                日常开发过程中难免会出现一些工程文件的冲突，在解决工程文件的冲突时，如果处理不好容易造成文件在编译选项中重复配置的情况。使用该命令可去除重复的编译文件
                DESC
                self.command = 'uniq'
                self.arguments = [
                    CLAide::Argument.new('project.xcodeproj', true)
                ]
                def self.options
                    [
                        ['--targetname=TargetName,TargetName', '指定需要操作的Target'],
                        ['--uniq-compile-sources', '对Build Phase中的Compile Sources中文件去重'],
                        ['--uniq-bundle-resources', '对Build Phase中Copy Bundle Resources中资源去重']
                    ]
                end
                def initialize(argv)
                    @proj_path = argv.shift_argument
                    @target_names = argv.option('targetname', '').split(',')
                    @uniq_compile_sources = argv.flag?('uniq-compile-sources', true)
                    @uniq_bundle_resources = argv.flag?('uniq-bundle-resources', true)
                    super
                end
      
                def validate!
                    super
                  help! 'An project.xcodeproj is required.' unless @proj_path
                end
      
                def run
                    require 'xcodeproj'
                    
                    project = Xcodeproj::Project.open(@proj_path)

                    # uniques array
                    uniq_phases = []
                    uniq_phases |= ['SourcesBuildPhase'] if @uniq_compile_sources
                    uniq_phases |= ['ResourcesBuildPhase'] if @uniq_bundle_resources

                    project.targets.each do |target|
                        next if @target_names.count > 0 && !@target_names.include?(target.name)
                        
                        target.build_phases.each do |phase|
                            phase.files.uniq! if uniq_phases.include?(phase.to_s)
                        end
                    end

                    project.save

                    puts 'xcodeproj files unique success'
                end
            end
        end
    end
end