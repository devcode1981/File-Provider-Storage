# frozen_string_literal: true

module GDK
  module Diagnostic
    class Status < Base
      TITLE = 'GDK Status'

      def diagnose
        shell = Shellout.new('gdk status')
        shell.run
        status = shell.read_stdout

        @down_services = status.split("\n").select { |svc| svc.match?(/\Adown: .+, want up;.+\z/) }
      end

      def success?
        @down_services.empty?
      end

      def detail
        <<~MESSAGE
          The following services are not running but should be:

          #{@down_services.join("\n")}
        MESSAGE
      end
    end
  end
end
