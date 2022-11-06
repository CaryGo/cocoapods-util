module Pod
  class Command
    class Util < Command
      class Repo < Util
        class Push < Repo
          self.summary = '`pod repo push`扩展功能，解决私有仓库验证不过无法推送的问题'
          self.description = <<-DESC
          和`pod repo push`命令使用步骤完全一致，可以设置参数`--skip-validate`跳过验证直接推送到私有仓库，不设置时调用原`push`的命令，不影响原功能。
          DESC
          self.arguments = Pod::Command::Repo::Push.arguments
          def self.options
            require_relative 'push_helper'
            Pod::Command::Repo::Push.options
          end

          def initialize(argv)
            @skip_validate = argv.flag?('skip-validate', false)
            @skip_build = argv.flag?('skip-build', false)
            super
            @argvs = argv.remainder!

            @repo = @argvs.first
          end

          def validate!
            help! 'A spec-repo name or url is required.' unless @repo
          end

          def run
            require_relative 'push_helper'
            
            @target = Pod::Command::Repo::Push.new(CLAide::ARGV.new(@argvs))
            @target.validate!
            @target.skip_validate = @skip_validate
            @target.skip_build = @skip_build
            @target.run
          end
        end
      end
    end
  end
end