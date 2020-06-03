# frozen_string_literal: true

module GDK
  module Diagnostic
    class Golang < Base
      TITLE = 'Golang'

      def diagnose
        go_get_command.try_run

        nil
      end

      def success?
        # Let's return success if the gitlab-elasticsearch-indexer clone does
        # not exist.
        return true unless clone_exists?

        go_get_command.success?
      end

      def detail
        return icu4c_issue_detail unless go_get_command.success?
      end

      private

      def clone_exists?
        clone_dir.exist?
      end

      def clone_dir
        config.gitlab_elasticsearch_indexer.__dir
      end

      def go_get_command
        @go_get_command ||= Shellout.new(%w[go get], chdir: clone_dir.to_s)
      end

      def icu4c_issue_detail
        <<~MESSAGE
          Golang is current unable to build binaries that use the icu4c package.
          You can try the following to fix:

          go clean -cache
        MESSAGE
      end
    end
  end
end
