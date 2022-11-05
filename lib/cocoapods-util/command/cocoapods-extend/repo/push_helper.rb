module Pod
    class Command
      class Repo < Command
        class Push < Repo
            attr_accessor :skip_validate
            
            class_alias_method(:old_options, :options)
            def self.options
              [
                ['--skip-validate', '跳过验证，不验证推送的podspec文件，默认为验证']
              ].concat(self.old_options)
            end

            # 调用原方法的两种方式
            old_validate_podspec_files = instance_method(:validate_podspec_files)
            define_method(:validate_podspec_files) do
                old_validate_podspec_files.bind(self).() unless @skip_validate
            end

            alias_method :old_check_repo_status, :check_repo_status
            def check_repo_status
                old_check_repo_status unless @skip_validate
            end
        end
      end
    end
end