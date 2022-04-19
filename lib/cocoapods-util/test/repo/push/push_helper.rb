module Pod
    class Command
      class Repo < Command
        class Push < Repo
            attr_accessor :spec_validate

            def self.options
              [
                ['--no-spec-validate', '不验证推送的podspec文件，默认验证'],
                ['--allow-warnings', 'Allows pushing even if there are warnings'],
                ['--use-libraries', 'Linter uses static libraries to install the spec'],
                ['--use-modular-headers', 'Lint uses modular headers during installation'],
                ["--sources=#{Pod::TrunkSource::TRUNK_REPO_URL}", 'The sources from which to pull dependent pods ' \
                 '(defaults to all available repos). Multiple sources must be comma-delimited'],
                ['--local-only', 'Does not perform the step of pushing REPO to its remote'],
                ['--no-private', 'Lint includes checks that apply only to public repos'],
                ['--skip-import-validation', 'Lint skips validating that the pod can be imported'],
                ['--skip-tests', 'Lint skips building and running tests during validation'],
                ['--commit-message="Fix bug in pod"', 'Add custom commit message. Opens default editor if no commit ' \
                  'message is specified'],
                ['--use-json', 'Convert the podspec to JSON before pushing it to the repo'],
                ['--swift-version=VERSION', 'The `SWIFT_VERSION` that should be used when linting the spec. ' \
                 'This takes precedence over the Swift versions specified by the spec or a `.swift-version` file'],
                ['--no-overwrite', 'Disallow pushing that would overwrite an existing spec'],
                ['--update-sources', 'Make sure sources are up-to-date before a push'],
              ].concat(super)
            end

            alias old_validate_podspec_files validate_podspec_files
            def validate_podspec_files
                UI.puts "validate_podspec_files"
                old_validate_podspec_files if @spec_validate
            end

            alias old_check_repo_status check_repo_status
            def check_repo_status
                UI.puts "check_repo_status"
                old_check_repo_status if @spec_validate
            end
        end
      end
    end
end