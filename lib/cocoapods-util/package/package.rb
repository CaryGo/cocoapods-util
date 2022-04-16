require 'cocoapods-util/package/helper/pod_utils'
require 'cocoapods-util/package/helper/builder'
require 'cocoapods-util/package/helper/framework'

require 'tmpdir'
require 'json'

module Pod
  class Command
    class Util < Command
        class Package < Util
            self.summary = '通过podspec编译静态库（library/framework/xcframework）。'
            self.description = "本插件属于在cocoapods-packager的基础上做的修改，仅支持编译静态库。另外支持use_modular_headers!、排除模拟器、排除特定架构、编译xcframework等。"
            self.arguments = [
              CLAide::Argument.new('NAME', true),
              CLAide::Argument.new('SOURCE', false)
            ]
    
            def self.options
              [
                ['--force',     'Overwrite existing files.'],
                ['--library',   'Generate static library.'],
                ['--framework',   'Generate static framework.'],
                ['--xcframework',   'Generate static xcframework.'],
                ['--local',     'Use local state rather than published versions.'],
                ['--configuration', 'Build the specified configuration (e.g. Debug). Defaults to Release'],
                ['--subspecs', 'Only include the given subspecs'],
                ['--spec-sources=private,https://github.com/CocoaPods/Specs.git', 'The sources to pull dependent ' \
                  'pods from (defaults to https://github.com/CocoaPods/Specs.git)'],
                ['--exclude-sim', '排除模拟器架构，仅编译真机对应的架构。'],
                ['--use-modular-headers', '开启use_modular_headers!'],
                ['--exclude-archs', '排除特定的架构，如`--exclude-archs=armv7s`'],
                ['--dependency-config', '依赖的pod文件配置，为一个json数组，可以配置分支、tag、source源等。[{"PodA":{"git":"xxx", "branch":"xxx"}},{"PodB":{"source":"xxx"}}]'],
                ['--contains-resources', '生成的framework中是否包含bundle文件，默认不把bundle文件放到framework中。'],
              ]
            end
    
            def initialize(argv)
              @framework = argv.flag?('framework')
              @xcframework = argv.flag?('xcframework')
              @library = argv.flag?('library')
              @local = argv.flag?('local', false)
              @package_type = if @xcframework
                                :static_xcframework
                              elsif @framework
                                :static_framework
                              elsif @library
                                :static_library
                              else
                                :static_library
                              end
              @force = argv.flag?('force')
              @exclude_sim = argv.flag?('exclude-sim', false)
              @use_modular_headers = argv.flag?('use-modular-headers', false)
              @name = argv.shift_argument
              @source = argv.shift_argument
              @spec_sources = argv.option('spec-sources', 'https://github.com/CocoaPods/Specs.git').split(',')
    
              subspecs = argv.option('subspecs')
              @subspecs = subspecs.split(',') unless subspecs.nil?
    
              @exclude_archs = argv.option('exclude-archs', '')
              @framework_contains_resources = argv.flag?('contains-resources', false)
    
              dependency_config = argv.option('dependency-config', '[]')
              @dependency_config = JSON.parse(dependency_config)
    
              @config = argv.option('configuration', 'Release')
    
              @source_dir = Dir.pwd
              @is_spec_from_path = false
              @spec = spec_with_path(@name)
              @is_spec_from_path = true if @spec
              @spec ||= spec_with_name(@name)
              super
            end
    
            def validate!
              super
              help! 'A podspec name or path is required.' unless @spec
              help! '--local option can only be used when a local `.podspec` path is given.' if @local && !@is_spec_from_path
              help! '编译静态库.a不允许设置包含resources' if !(@framework || @xcframework) && @framework_contains_resources
            end
    
            def run
              if @spec.nil?
                help! 'Unable to find a podspec with path or name.'
                return
              end
    
              target_dir, work_dir = create_working_directory
              return if target_dir.nil?
              build_package
    
              `mv "#{work_dir}" "#{target_dir}"`
              Dir.chdir(@source_dir)
            end
    
            private
    
            def build_in_sandbox(platform)
              config.installation_root  = Pathname.new(Dir.pwd)
              config.sandbox_root       = 'Pods'
    
              static_sandbox = build_static_sandbox()
              static_installer = install_pod(platform.name, static_sandbox)
    
              begin
                perform_build(platform, static_sandbox, static_installer)
              ensure # in case the build fails; see Builder#xcodebuild.
                Pathname.new(config.sandbox_root).rmtree
                FileUtils.rm_f('Podfile.lock')
                # clean build
                FileUtils.rm_rf('build')
              end
            end
    
            def build_package
              @spec.available_platforms.each do |platform|
                # 暂时仅支持ios框架的编译
                if platform.name.to_s == 'ios'
                  build_in_sandbox(platform)
                end
              end
            end
    
            def create_target_directory
              target_dir = "#{@source_dir}/#{@spec.name}-#{@spec.version}"
              if File.exist? target_dir
                if @force
                  Pathname.new(target_dir).rmtree
                else
                  UI.puts "Target directory '#{target_dir}' already exists."
                  return nil
                end
              end
              target_dir
            end
    
            def create_working_directory
              target_dir = create_target_directory
              return if target_dir.nil?
    
              work_dir = Dir.tmpdir + '/cocoapods-' + Array.new(8) { rand(36).to_s(36) }.join
              # work_dir = "#{@source_dir}" + '/cocoapods-' + Array.new(8) { rand(36).to_s(36) }.join
              puts "#{work_dir}"
              Pathname.new(work_dir).mkdir
              Dir.chdir(work_dir)
    
              [target_dir, work_dir]
            end
    
            def perform_build(platform, static_sandbox, static_installer)
              static_sandbox_root = config.sandbox_root.to_s
    
              builder = Pod::Builder.new(
                platform,
                static_installer,
                @source_dir,
                static_sandbox_root,
                static_sandbox.public_headers.root,
                @spec,
                @config,
                @exclude_sim,
                @exclude_archs,
                @framework_contains_resources
              )
    
              builder.build(@package_type)
            end
        end
    end
  end
end

