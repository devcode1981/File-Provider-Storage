# frozen_string_literal: true

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
      EXPECTED_GO_VERSION = '1.12'
      EXPECTED_YARN_VERSION = '1.12'
      EXPECTED_NODEJS_VERSION = '12.10'
      EXPECTED_POSTGRESQL_VERSION = '9.6.x'

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
        check_postgresql_version

        check_graphicsmagick_installed
        check_exiftool_installed
        check_minio_installed
        check_runit_installed
      end

      def check_git_version
        current_git_version = `git version`[/git version (\d+\.\d+.\d+)/, 1]

        actual = Gem::Version.new(current_git_version)
        expected = Gem::Version.new(EXPECTED_GIT_VERSION)

        if actual < expected
          @error_messages << require_minimum_version('Git', actual, expected)
        end
      end

      def check_ruby_version
        actual = Gem::Version.new(RUBY_VERSION)
        expected = Gem::Version.new(GitLabVersions.new.ruby_version)

        if actual < expected
          @error_messages << require_minimum_version('Ruby', actual, expected)
        end
      end

      def check_bundler_version
        unless system("bundle _#{expected_bundler_version}_ --version >/dev/null 2>&1")
          @error_messages << <<~BUNDLER_VERSION_NOT_MET
            Please install Bundler version #{expected_bundler_version}.
            gem install bundler -v '= #{expected_bundler_version}'
          BUNDLER_VERSION_NOT_MET
        end
      end

      def check_go_version
        current_version = `go version`[/go((\d+.\d+)(.\d+)?)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_GO_VERSION)
        if actual < expected
          @error_messages << require_minimum_version('Go', actual, expected)
        end

      rescue Errno::ENOENT
        @error_messages << missing_dependency('Go', minimum_version: EXPECTED_GO_VERSION)
      end

      def check_nodejs_version
        current_version = `node --version`[/v(\d+\.\d+\.\d+)/, 1]

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_NODEJS_VERSION)

        if actual < expected
          @error_messages << require_minimum_version('Node.js', actual, expected)
        end

      rescue Errno::ENOENT
        @error_messages << missing_dependency('Node.js', minimum_version: EXPECTED_NODEJS_VERSION)
      end

      def check_yarn_version
        current_version = `yarn --version`

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_YARN_VERSION)

        if actual < expected
          @error_messages << require_minimum_version('Yarn', actual, expected)
        end

      rescue Errno::ENOENT
        @error_messages << missing_dependency('Yarn', minimum_version: expected)
      end

      def check_postgresql_version
        current_postgresql_version = `psql --version`[/psql \(PostgreSQL\) (\d+\.\d+)/, 1]

        actual = Gem::Version.new(current_postgresql_version)
        expected = Gem::Version.new(EXPECTED_POSTGRESQL_VERSION)

        if actual.segments[0] < expected.segments[0]
          @error_messages << require_minimum_version('PostgreSQL', actual, expected)
        end
      end

      def check_graphicsmagick_installed
        unless system("gm version >/dev/null 2>&1")
          @error_messages << missing_dependency('GraphicsMagick')
        end
      end

      def check_exiftool_installed
        unless system("exiftool -ver >/dev/null 2>&1")
          @error_messages << missing_dependency('Exiftool')
        end
      end

      def check_minio_installed
        unless system("minio version >/dev/null 2>&1 || minio --version >/dev/null 2>&1")
          @error_messages << missing_dependency('MinIO')
        end
      end

      def check_runit_installed
        unless system("which runsvdir >/dev/null 2>&1")
          @error_messages << missing_dependency('Runit')
        end
      end

      def require_minimum_version(dependency, actual, expected)
        "#{dependency} version #{actual} detected, please install #{dependency} version #{expected} or higher."
      end

      def missing_dependency(dependency, minimum_version: nil)
        message = "#{dependency} is not installed, please install #{dependency}"
        message += "#{minimum_version} or higher" unless minimum_version.nil?
        message + "."
      end

      private

      def expected_bundler_version
        @expected_bundler_version ||= GitLabVersions.new.bundler_version.freeze
      end
    end
  end
end
