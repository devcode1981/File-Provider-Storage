require 'net/http'

module GDK
  module Dependencies
    class GitLabVersions
      VersionNotDetected = Class.new(StandardError)

      def ruby_version
        read_gitlab_file('.ruby-version').strip || raise(VersionNotDetected, "Failed to determine GitLab's Ruby version")
      end

      def bundler_version
        read_gitlab_file('Gemfile.lock')[/BUNDLED WITH\n +(\d+.\d+.\d+)/, 1] || raise(VersionNotDetected, "Failed to determine GitLab's Bundler version")
      end

      private

      def read_gitlab_file(filename)
        return local_gitlab_path(filename).read if local_gitlab_path(filename).exist?

        read_remote_file(filename)
      end

      def local_gitlab_path(filename)
        Pathname.new(__dir__).join("../../gitlab/#{filename}").expand_path
      end

      def read_remote_file(filename)
        uri = URI("https://gitlab.com/gitlab-org/gitlab/raw/master/#{filename}")
        Net::HTTP.get(uri)
      rescue SocketError
        abort 'Internet connection is required to set up GDK, please ensure you have an internet connection'
      end
    end

    class Checker
      EXPECTED_GIT_VERSION = '2.22'
      EXPECTED_RUBY_VERSION = GitLabVersions.new.ruby_version.freeze
      EXPECTED_BUNDLER_VERSION = GitLabVersions.new.bundler_version.freeze
      EXPECTED_GO_VERSION = '1.12'
      EXPECTED_YARN_VERSION = '1.12'
      EXPECTED_NODEJS_VERSION = '12.x'

      attr_reader :error_messages

      def initialize
        @error_messages = []
      end

      def check_all
        check_git_version
        check_ruby_version
        check_bundler_version
        check_go_version
        check_nodejs_version
        check_yarn_version
      end

      def check_git_version
        current_git_version = `git version`[/git version (\d+\.\d+.\d+)/, 1]

        actual = Gem::Version.new(current_git_version)
        expected = Gem::Version.new(EXPECTED_GIT_VERSION)

        if actual < expected
          @error_messages << <<~GIT_VERSION_NOT_MET
            We've detected that you are using Git version #{actual}.
            Please install Git version #{EXPECTED_GIT_VERSION} or higher.
          GIT_VERSION_NOT_MET
        end
      end

      def check_ruby_version
        actual = Gem::Version.new(RUBY_VERSION)
        expected = Gem::Version.new(EXPECTED_RUBY_VERSION)

        if actual < expected
          @error_messages << <<~RUBY_VERSION_NOT_MET
            We've detected that you are using Ruby version #{actual}.
            Please install Ruby version #{EXPECTED_RUBY_VERSION} or higher.
          RUBY_VERSION_NOT_MET
        end
      end

      def check_bundler_version
        unless system("bundle _#{EXPECTED_BUNDLER_VERSION}_ --version >/dev/null 2>&1")
          @error_messages << <<~BUNDLER_VERSION_NOT_MET
            Please install Bundler version #{EXPECTED_BUNDLER_VERSION}.
            gem install bundler -v '= #{EXPECTED_BUNDLER_VERSION}'
          BUNDLER_VERSION_NOT_MET
        end
      end

      def check_go_version
        current_version = `go version`[/go((\d+.\d+)(.\d+)?)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_GO_VERSION)
        if actual < expected
          @error_messages << <<~GO_VERSION_NOT_MET
            We've detected that you are using Go version #{actual}.
            Please install Go version #{EXPECTED_GO_VERSION} or higher.
          GO_VERSION_NOT_MET
        end

      rescue Errno::ENOENT
        @error_messages << <<~MISSING_GO
          Go is not installed, please install Go #{EXPECTED_GO_VERSION} or higher.
        MISSING_GO
      end

      def check_nodejs_version
        current_version = `node --version`[/v(\d+\.\d+\.\d+)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_NODEJS_VERSION)

        if actual < expected
          @error_messages << <<~NODEJS_VERSION_NOT_MET
            We've detected that you are using Node.js version #{actual}.
            Please install Node.js version #{EXPECTED_NODEJS_VERSION} or higher.
          NODEJS_VERSION_NOT_MET
        end

      rescue Errno::ENOENT
        @error_messages << <<~MISSING_NODEJS
          Node.js is not installed, please install Node.js #{EXPECTED_NODEJS_VERSION} or higher.
        MISSING_NODEJS
      end

      def check_yarn_version
        current_version = `yarn --version`

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_YARN_VERSION)

        if actual < expected
          @error_messages << <<~YARN_VERSION_NOT_MET
            We've detected that you are using Yarn version #{actual}.
            Please install Yarn version #{EXPECTED_YARN_VERSION} or higher.
          YARN_VERSION_NOT_MET
        end

      rescue Errno::ENOENT
        @error_messages << <<~MISSING_YARN
          Yarn is not installed, please install Yarn #{EXPECTED_YARN_VERSION} or higher.
        MISSING_YARN
      end
    end
  end
end
