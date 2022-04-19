module Pod
    class Command
      class Repo < Command
        class Push < Repo
            alias old_check_if_push_allowed check_if_push_allowed
            def check_if_push_allowed
                UI.puts "check_if_push_allowed"
                old_check_if_push_allowed
            end

            alias old_validate_podspec_files validate_podspec_files
            def validate_podspec_files
                UI.puts "check_if_push_allowed"
                old_validate_podspec_files
            end
        end
      end
    end
end