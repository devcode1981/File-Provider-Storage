require 'net/http'

module GDK
  module Dependencies
    GITLAB_RUBY_VERSION_URL = 'https://gitlab.com/gitlab-org/gitlab/raw/master/.ruby-version'
    GIT_VERSION = '2.22'
    GITLAB_RUBY_VERSION = Net::HTTP.get(URI(GITLAB_RUBY_VERSION_URL)).strip.freeze
    BUNDLER_VERSION = IO.read('Gemfile.lock')[/BUNDLED WITH\n +(\d+.\d+.\d+)/, 1].freeze
    GO_VERSION = '1.12'
    YARN_VERSION = '1.12'
    NODEJS_VERSION = '12.x'

    class Checker
      attr_reader :error_messages

      def initialize
        @error_messages = []
      end

      def check
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
        expected = Gem::Version.new(GIT_VERSION)

        if actual < expected
          @error_messages << <<~GIT_VERSION_NOT_MET
            We've detected that you are using Git version #{actual}.
            Please install Git version #{GIT_VERSION} or higher.
          GIT_VERSION_NOT_MET
        end
      end

      def check_ruby_version
        actual = Gem::Version.new(RUBY_VERSION)
        expected = Gem::Version.new(GITLAB_RUBY_VERSION)

        if actual < expected
          @error_messages << <<~RUBY_VERSION_NOT_MET
            We've detected that you are using Ruby version #{actual}.
            Please install Ruby version #{GITLAB_RUBY_VERSION} or higher.
          RUBY_VERSION_NOT_MET
        end
      end

      def check_bundler_version
        current_version = `bundler --version`[/(\d+.\d+.\d+)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(BUNDLER_VERSION)

        if actual != expected
          @error_messages << <<~BUNDLER_VERSION_NOT_MET
            We've detected that you are using Bundler version #{actual}.
            Please install Bundler version #{BUNDLER_VERSION}.
          BUNDLER_VERSION_NOT_MET
        end
      rescue Errno::ENOENT
        @error_messages << <<~MISSING_BUNDLER
          Bundler is not installed, please install Bundler #{BUNDLER_VERSION}.
        MISSING_BUNDLER
      end

      def check_go_version
        current_version = `go version`[/go((\d+.\d+)(.\d+)?)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(GO_VERSION)
        if actual < expected
          @error_messages << <<~GO_VERSION_NOT_MET
            We've detected that you are using Go version #{actual}.
            Please install Go version #{GO_VERSION} or higher.
          GO_VERSION_NOT_MET
        end

      rescue Errno::ENOENT
        @error_messages << <<~MISSING_GO
          Go is not installed, please install Go #{GO_VERSION} or higher.
        MISSING_GO
      end

      def check_nodejs_version
        current_version = `node --version`[/v(\d+\.\d+\.\d+)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(NODEJS_VERSION)

        if actual < expected
          @error_messages << <<~NODEJS_VERSION_NOT_MET
            We've detected that you are using Node.js version #{actual}.
            Please install Node.js version #{NODEJS_VERSION} or higher.
          NODEJS_VERSION_NOT_MET
        end

      rescue Errno::ENOENT
        @error_messages << <<~MISSING_NODEJS
          Node.js is not installed, please install Node.js #{NODEJS_VERSION} or higher.
        MISSING_NODEJS
      end

      def check_yarn_version
        current_version = `yarn --version`

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(YARN_VERSION)

        if actual < expected
          @error_messages << <<~YARN_VERSION_NOT_MET
            We've detected that you are using Yarn version #{actual}.
            Please install Yarn version #{YARN_VERSION} or higher.
          YARN_VERSION_NOT_MET
        end

      rescue Errno::ENOENT
        @error_messages << <<~MISSING_YARN
          Yarn is not installed, please install Yarn #{YARN_VERSION} or higher.
        MISSING_YARN
      end
    end
  end
end
