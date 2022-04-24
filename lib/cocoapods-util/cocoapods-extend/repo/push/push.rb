module Pod
  class Command
    class Util < Command
      class Repo < Util
        class Push < Repo
          self.summary = '和`pod repo push`命令使用步骤完全一致，可以设置参数`--skip-validate`跳过验证直接推送到私有仓库，不设置时调用原`push`的命令，不影响原功能。使用`pod util repo push --help`查看更多。'
          def initialize(argv)
            @skip_validate = argv.flag?('skip-validate', false)
            super
            @argvs = argv.remainder!
          end

          def validate!
            # 用到的时候再加载
            require 'cocoapods-util/cocoapods-extend/repo/push/push_helper'
            @target = Pod::Command::Repo::Push.new(CLAide::ARGV.new(@argvs))
            @target.validate!
          end

          def run
            @target.skip_validate = @skip_validate
            @target.run
          end
        end
      end
    end
  end
end