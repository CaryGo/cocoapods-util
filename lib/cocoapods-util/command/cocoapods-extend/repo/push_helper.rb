module Pod
    class Command
      class Repo < Command
        class Push < Repo
            attr_accessor :skip_validate, :skip_build
            
            class_alias_method(:old_options, :options)
            def self.options
              [
                ['--skip-validate', '跳过整个验证，不验证推送的podspec文件，默认为验证'],
                ['--skip-build', '跳过编译过程，还是会校验pod下载和依赖']
              ].concat(self.old_options)
            end

            # 调用原方法的两种方式
            old_validate_podspec_files = instance_method(:validate_podspec_files)
            define_method(:validate_podspec_files) do
                Pod::Validator.skip_build = @skip_build
                old_validate_podspec_files.bind(self).() unless @skip_validate
                Pod::Validator.skip_build = false
            end

            alias_method :old_check_repo_status, :check_repo_status
            def check_repo_status
                old_check_repo_status unless @skip_validate
            end
        end
      end
    end
end

module Pod
  class Validator
    class_attr_accessor :skip_build

    alias_method :old_build_pod, :build_pod
    def build_pod
      old_build_pod unless Pod::Validator.skip_build
    end

    alias_method :old_test_pod, :test_pod
    def test_pod
      old_test_pod unless Pod::Validator.skip_build
    end
  end
end