# frozen_string_literal: true

require 'open3'
require 'stringio'

module GDK
  module Command
    class Doctor
      def run
        gdk_start

        success = true

        checks.each do |check|
          out = send(check)
          next if out.nil? || out.empty?

          puts out
          success = false
        end

        exit(1) unless success

        puts 'GDK is ready.'
      end

      def checks
        [
          :check_dependencies,
          :check_gdk_version,
          :check_gdk_status,
          :check_pending_migrations,
          :check_diff_config
        ]
      end

      def check_dependencies
        checker = Dependencies::Checker.new
        checker.check_all
        return if checker.error_messages.empty?

        <<~MESSAGE
          #{header('Inspecting gdk dependencies...')}
          Some GDK dependencies are not installed.
          #{checker.error_messages.join("\n")}
        MESSAGE
      end

      def check_gdk_version
        gdk_master = `git show-ref refs/remotes/origin/master -s --abbrev`
        head = `git rev-parse --short HEAD`

        return if head == gdk_master

        <<~MESSAGE
          #{header('Inspecting gdk version...')}
          This GDK might be out-of-date with master.
          If you are not currently developing GDK, consider updating GDK with `gdk update`.
        MESSAGE
      end

      def check_gdk_status
        shell = Shellout.new('gdk status')
        shell.run
        status = shell.read_stdout

        down_services = status.split("\n").select { |svc| svc.start_with?('down') }
        return if down_services.empty?

        <<~MESSAGE
          #{header('Inspecting gdk status...')}
          These services are not running.
          #{down_services.join("\n")}
        MESSAGE
      end

      def check_pending_migrations
        shellout = Shellout.new(%W[bundle exec rails db:abort_if_pending_migrations], chdir: 'gitlab')
        shellout.run

        return if shellout.success?

        <<~MESSAGE
          #{header('Inspecting migrations...')}
          There are pending migrations.
          Run `cd gitlab && rails db:migrate` to update your database then try again.
        MESSAGE
      end

      def check_diff_config
        out = StringIO.new
        err = StringIO.new

        DiffConfig.new.run(stdout: out, stderr: err)

        out.close
        err.close

        config_diff = out.string
        return if config_diff.empty?

        <<~MESSAGE
          #{header('Inspecting gdk configuration...')}
          We have detected changes in GDK configuration,
          please review the following diff or consider `gdk reconfigure`.
          #{config_diff}
        MESSAGE
      end

      private

      def gdk_start
        Shellout.new('gdk start').run
      end

      def header(message)
        ['*' * 80, message].join("\n")
      end
    end
  end
end

