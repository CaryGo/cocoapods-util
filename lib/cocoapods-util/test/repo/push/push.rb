require 'cocoapods-util/test/repo/push/push_helper.rb'

module Pod
  class Command
    class Util < Command
      class Repo < Util
        class Push < Repo
          def initialize(argv)
            @skip_validate = argv.flag?('skip-validate', false)
            super
            @argvs = argv.remainder!
          end

          def validate!
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