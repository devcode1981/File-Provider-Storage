# frozen_string_literal: true

module GDK
  module Diagnostic
    class Version < Base
      TITLE = 'GDK Version'

      def diagnose
        @gdk_master = `git show-ref refs/remotes/origin/master -s --abbrev`
        @head = `git rev-parse --short HEAD`
      end

      def success?
        @head == @gdk_master
      end

      def detail
        <<~MESSAGE
          An update for GDK is available. Unless you are developing on GDK itself,
          consider updating GDK with `gdk update`.
        MESSAGE
      end
    end
  end
end
