# frozen_string_literal: true

module GDK
  module CMD
    class Doctor
      def run
        check_dependencies
      end

      def check_dependencies
        puts 'Inspecting dependencies...'
        checker = Dependencies::Checker.new
        checker.check_all
        if checker.error_messages.empty?
          puts checker.error_messages
        end
      end
    end
  end
end

