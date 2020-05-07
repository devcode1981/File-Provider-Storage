# frozen_string_literal: true

module GDK
  module Diagnostic
    class Version < Base
      TITLE = 'GDK Version'

      def diagnose
        fetch
      end

      def success?
        !behind_origin_master?
      end

      def detail
        "An update for GDK is available."
      end

      private

      def fetch
        run(%w[git fetch])
      end

      def behind_origin_master?
        run(%w[git rev-list --left-only --count origin/master...@]).to_i.positive?
      end

      def run(cmd)
        Shellout.new(cmd, chdir: config.gdk_root).run
      end
    end
  end
end
