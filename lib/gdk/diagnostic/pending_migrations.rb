# frozen_string_literal: true

module GDK
  module Diagnostic
    class PendingMigrations < Base
      TITLE = 'Database Migrations'

      def diagnose
        @shellout = Shellout.new(%w[bundle exec rails db:abort_if_pending_migrations], chdir: config.gitlab.dir)
        @shellout.run
      end

      def success?
        @shellout.success?
      end

      def detail
        <<~MESSAGE
          There are pending database migrations.
          To update your database, run `cd gitlab && bundle exec rails db:migrate`.
        MESSAGE
      end
    end
  end
end
