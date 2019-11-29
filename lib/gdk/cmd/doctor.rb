# frozen_string_literal: true

module GDK
  module CMD
    class Doctor
      def run
        check_dependencies
        check_diff_config
        check_gdk_version
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

      def check_gdk_version
        puts 'Inspecting gdk version...'
        gdk_master = `git show-ref refs/remotes/origin/master -s --abbrev`
        head = `git rev-parse --short HEAD`

        unless head == gdk_master
          puts 'This GDK might be out-of-date, consider updating GDK with `gdk update`.'
        end
      end
    end
  end
end

