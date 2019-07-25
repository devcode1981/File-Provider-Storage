require 'erb'
require 'fileutils'
require_relative '../gdk/config'

module Runit
  class Config
    attr_reader :gdk_root

    COLORS = {
      red: '31',
      green: '32',
      yellow: '33',
      blue: '34',
      magenta: '35',
      cyan: '36',
      bright_red: '31;1',
      bright_green: '32;1',
      bright_yellow: '33;1',
      bright_blue: '34;1',
      bright_magenta: '35;1',
      bright_cyan: '36;1'
    }.freeze

    def initialize(gdk_root)
      @gdk_root = gdk_root
    end

    def log_dir
      File.join(gdk_root, 'log')
    end

    def services_dir
      File.join(gdk_root, 'services')
    end

    def sv_dir
      File.join(gdk_root, 'sv')
    end

    def run_env
      @run_env ||= GDK::Config.new.dump_run_env!
    end

    def render
      FileUtils.mkdir_p(services_dir)
      FileUtils.mkdir_p(log_dir)

      services = File.read('Procfile').lines.map do |line|
        line.chomp!
        next if line.start_with?('#')

        service, command = line.split(': ', 2)
        next unless service && command

        [service, command]
      end.compact

      services.each_with_index do |(service, command), i|
        create_runit_service(service, command, i)
      end
    end

    private

    def create_runit_service(service, command, index)
      dir = File.join(sv_dir, service)

      run_template = <<~TEMPLATE
        #!/bin/sh
        set -e

        exec 2>&1
        cd <%=  gdk_root %>

        <%= run_env %>

        test -f env.runit && . env.runit

        <%= command %>
      TEMPLATE

      run_path = File.join(dir, 'run')
      write_file(run_path, ERB.new(run_template).result(binding), 0o755)

      service_log_dir = File.join(log_dir, service)
      FileUtils.mkdir_p(service_log_dir)

      log_run_template = <<~TEMPLATE
        #!/bin/sh
        set -e

        # svlogd is a long-running daemon so it should run from /
        cd /

        exec svlogd <%= service_log_dir %>
      TEMPLATE

      log_run_path = File.join(dir, 'log/run')
      write_file(log_run_path, ERB.new(log_run_template).result(binding), 0o755)

      # See http://smarden.org/runit/svlogd.8.html#sect6 for documentation of the svlogd config file
      log_config_template = <<~TEMPLATE
        # zip old log files
        !gzip
        # custom log prefix for <%= service %>
        p<%= ansi(color(index)) + service + ansi(0) + ': ' %>
        # keep at most 1 old log file
        n1
      TEMPLATE

      log_config_path = File.join(service_log_dir, 'config')
      write_file(log_config_path, ERB.new(log_config_template).result(binding), 0o644)

      # Create a 'down' file so that runsvdir won't boot this service until
      # you request it with `sv start`.
      write_file(File.join(dir, 'down'), '', 0o644)

      # If the user removes this symlink, runit will stop managing this service.
      FileUtils.ln_sf(dir, File.join(services_dir, service))
    end

    def write_file(path, content, perm)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(content) }
      File.chmod(perm, path)
    end

    def color(index)
      COLORS.values[index % COLORS.size]
    end

    def ansi(code)
      "\e[#{code}m"
    end
  end
end
