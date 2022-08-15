module Pod
    class Command
      class Util < Command
        class Developer < Util
          class MobileProvision < Developer
            self.summary = '展示和清除本机安装的描述文件'
            self.command = 'mobileprovision'
            self.arguments = [
                CLAide::Argument.new('Provisioning Profiles PATH', false)
            ]
            def self.options
                [
                    ["--list", "列出本机安装的所有描述文件"],
                    ["--clean", "清除本机已安装的所有描述文件"]
                ]
            end

            def initialize(argv)
                @list = argv.flag?("list", true)
                @clean = argv.flag?("clean", false)

                @profile_path = argv.shift_argument || "~/Library/MobileDevice/Provisioning\ Profiles/"
                super
            end
  
            def validate!
              super
            end
  
            def run
                @profile_path = File.expand_path(@profile_path)
                if !File.exist?(@profile_path)
                    UI.puts "没有找到`mobile provision`的安装路径, #{@profile_path}"
                    return
                end

                if @clean
                    clean_pp
                else
                    find_pp
                end
            end
            
            private
            def clean_pp
                path = Pathname.new(@profile_path)
                FileUtils.chdir(path)

                Dir.glob("*.mobileprovision").each do |file|
                    FileUtils.rm_rf(file)
                end
                UI.puts "mobileprovision files clean success"
            end

            def find_pp
                path = Pathname.new(@profile_path)
                FileUtils.chdir(path)

                index = 1
                Dir.glob("*.mobileprovision").each do |file|
                    pp_name = print_pp_info("Name", file)
                    pp_identifier = print_pp_info("Entitlements:application-identifier", file)
                    pp_uuid = print_pp_info("UUID", file)
                    UI.puts "#{index})".red " #{pp_name}".blue " #{pp_identifier}".yellow
                    index += 1
                end
            end
            
            def print_pp_info(name, file)
                command = "/usr/libexec/PlistBuddy -c 'Print :#{name}' /dev/stdin <<< $(security cms -D -u 11 -i #{file})"
                `#{command}`.lines.to_a.first.strip!
            end

          end
        end
      end
    end
  end