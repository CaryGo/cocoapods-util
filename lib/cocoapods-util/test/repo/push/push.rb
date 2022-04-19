require 'cocoapods-util/test/repo/push/push_helper.rb'

module Pod
  class Command
    class Util < Command
      class Repo < Util
        class Push < Repo
          def initialize(argv)
            super
            @argvs = argv.remainder!
          end

          def validate!
            @target = Pod::Command::Repo::Push.new(CLAide::ARGV.new(@argvs))
            @target.validate!
          end

          def run
            @target.run
          end
        end
      end
    end
  end
end