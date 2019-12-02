# frozen_string_literal: true

module GDK
  module Command
    class Doctor
      def run
        check_dependencies
        check_diff_config
        check_gdk_version
        check_gdk_status
      end

      def check_dependencies
        header('Inspecting gdk dependencies...')
        checker = Dependencies::Checker.new
        checker.check_all
        if checker.error_messages.empty?
          puts checker.error_messages
        end
      end

      def check_diff_config
        header('Inspecting gdk config...')
        DiffConfig.new.run
      end

      def check_gdk_version
        header('Inspecting gdk version...')
        gdk_master = `git show-ref refs/remotes/origin/master -s --abbrev`
        head = `git rev-parse --short HEAD`

        unless head == gdk_master
          puts 'This GDK might be out-of-date, consider updating GDK with `gdk update`.'
        end
      end

      def check_gdk_status
        header('Inspecting gdk status...')
        Runit.sv('status', ARGV)
      end

      private

      def header(message)
        puts '*'*80
        puts message
      end
    end
  end
end

