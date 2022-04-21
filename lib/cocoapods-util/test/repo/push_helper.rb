class Module
    def strong_alias(to, from)
      # https://tieba.baidu.com/p/5535445605?red_tag=0735709674  贴吧大神给出的方案
      # 类方法可以看做singleton class（单例类）的实例方法，下面两个方法都可以，上面这个方式也适用于早起的ruby版本
      (class << self;self;end).send(:alias_method, to, from)
      # self.singleton_class.send(:alias_method, to, from)
    end
end

module Pod
    class Command
      class Repo < Command
        class Push < Repo
            attr_accessor :skip_validate

            self.strong_alias(:old_options, :options)
            def self.options
              [
                ['--skip-validate', '跳过验证，不验证推送的podspec文件，默认为验证']
              ].concat(self.old_options)
            end

            # 调用原方法的两种方式
            old_validate_podspec_files = instance_method(:validate_podspec_files)
            define_method(:validate_podspec_files) do
                UI.puts "validate_podspec_files"
                old_validate_podspec_files.bind(self).() unless @skip_validate
            end

            alias :old_check_repo_status :check_repo_status
            def check_repo_status
                UI.puts "check_repo_status"
                old_check_repo_status unless @skip_validate
            end
        end
      end
    end
end