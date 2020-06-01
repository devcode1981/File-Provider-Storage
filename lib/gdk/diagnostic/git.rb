# frozen_string_literal: true

module GDK
  module Diagnostic
    class Git < Base
      TITLE = 'Git'

      MINIMUM_VERSION = '2.24.0'
      RECOMMENDED_VERSION = '2.26.0'

      def diagnose
        version
      end

      def success?
        command.success? && !version_too_old? && !version_not_the_recommended?
      end

      def detail
        return cant_determine_version_detail unless command.success?
        return version_too_old_detail if version_too_old?
        return version_not_the_recommended_detail if version_not_the_recommended?
      end

      private

      def command
        @command ||= Shellout.new(%w[git --version])
      end

      def version
        @version ||= begin
          return if command.try_run.empty?

          command.read_stdout.match(/(\d{1,}\.\d{1,}\.\d{1,})/)[0]
        end
      end

      def version_too_old?
        Gem::Version.new(version) < Gem::Version.new(MINIMUM_VERSION)
      end

      def version_not_the_recommended?
        Gem::Version.new(version) < Gem::Version.new(RECOMMENDED_VERSION)
      end

      def cant_determine_version_detail
        "Cannot determine Git version, is git installed?"
      end

      def version_too_old_detail
        "Git version #{version} is too old.  You need at least #{MINIMUM_VERSION}."
      end

      def version_not_the_recommended_detail
        "Git version #{version} is OK but at least #{RECOMMENDED_VERSION} is recommended."
      end
    end
  end
end
