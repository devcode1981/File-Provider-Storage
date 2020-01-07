# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

require_relative 'gdk/output'
require_relative 'gdk/env'
require_relative 'gdk/config'
require_relative 'gdk/command'
require_relative 'gdk/dependencies'
require_relative 'gdk/diagnostic'
require_relative 'gdk/erb_renderer'
require_relative 'gdk/logo'
require_relative 'runit'

module GDK
  PROGNAME = 'gdk'.freeze
  MAKE = RUBY_PLATFORM =~ /bsd/ ? 'gmake' : 'make'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    if !install_root_ok? && ARGV.first != 'reconfigure'
      puts <<-EOS.gsub(/^\s+\|/, '')
        |According to #{ROOT_CHECK_FILE} this gitlab-development-kit
        |installation was moved. Run 'gdk reconfigure' to update hard-coded
        |paths.
      EOS
      return false
    end

    case subcommand = ARGV.shift
    when 'run'
      abort <<~MSG
        'gdk run' is no longer available; see doc/runit.md.

        Use 'gdk start', 'gdk stop', and 'gdk tail' instead.
      MSG
    when 'install'
      exec(MAKE, *ARGV, chdir: $gdk_root)
    when 'update'
      # Otherwise we would miss it and end up in a weird state.
      puts "-------------------------------------------------------"
      puts "Running `make self-update`.."
      puts "-------------------------------------------------------"
      puts "Running separately in case the Makefile is updated.\n"
      system(MAKE, 'self-update', chdir: $gdk_root)

      puts "\n-------------------------------------------------------"
      puts "Running `make self-update update`.."
      puts "-------------------------------------------------------"
      exec(MAKE, 'self-update', 'update', chdir: $gdk_root)
    when 'diff-config'
      GDK::Command::DiffConfig.new.run

      true
    when 'config'
      config_command = ARGV.shift
      abort 'Usage: gdk config get path.to.the.conf.value' if config_command != 'get' || ARGV.empty?

      begin
        puts Config.new.dig(*ARGV)
        true
      rescue GDK::ConfigSettings::SettingUndefined
        abort "Cannot get config for #{ARGV.join('.')}"
      end
    when 'reconfigure'
      remember!($gdk_root)
      exec(MAKE, 'touch-examples', 'unlock-dependency-installers', 'postgresql-sensible-defaults', 'all', chdir: $gdk_root)
    when 'psql'
      pg_port = Config.new.postgresql.port

      exec('psql', '-h', File.join($gdk_root, 'postgresql'), '-p', pg_port.to_s, *ARGV, chdir: $gdk_root)
    when 'redis-cli'
      exec('redis-cli', '-s', File.join($gdk_root, 'redis/redis.socket'), *ARGV, chdir: $gdk_root)
    when 'env'
      GDK::Env.exec(ARGV)
    when 'start', 'status'
      exit(Runit.sv(subcommand, ARGV))
    when 'restart'
      exit(Runit.sv('force-restart', ARGV))
    when 'stop'
      if ARGV.empty?
        # Runit.stop will stop all services and stop Runit (runsvdir) itself.
        # This is only safe if all services are shut down; this is why we have
        # an integrated method for this.
        Runit.stop
        exit
      else
        # Stop the requested services, but leave Runit itself running.
        exit(Runit.sv('force-stop', ARGV))
      end
    when 'tail'
      Runit.tail(ARGV)
    when 'thin'
      # We cannot use Runit.sv because that calls Kernel#exec. Use system instead.
      system('gdk', 'stop', 'rails-web')
      exec(
        { 'RAILS_ENV' => 'development' },
        *%W[bundle exec thin --socket=#{$gdk_root}/gitlab.socket start],
        chdir: File.join($gdk_root, 'gitlab')
      )
    when 'doctor'
      GDK::Command::Doctor.new.run
      true
    when 'help'
      GDK::Command::Help.new.run
      true
    else
      GDK::Command::Help.new.run
      false
    end
  end

  def self.install_root_ok?
    expected_root = File.read(File.join($gdk_root, ROOT_CHECK_FILE)).chomp
    File.realpath(expected_root) == File.realpath($gdk_root)
  rescue => ex
    warn ex
    false
  end
end
