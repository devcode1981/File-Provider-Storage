# frozen_string_literal: true

module GDK
  module CMD
    class Doctor
      def run
        check_dependencies
        check_diff_config
      end

      def check_dependencies
        puts 'Inspecting dependencies...'
        checker = Dependencies::Checker.new
        checker.check_all
        if checker.error_messages.empty?
          puts checker.error_messages
        end
      end

      def check_diff_config
        puts 'Inspecting config...'
        DiffConfig.new.run
      end

    end
  end
end

