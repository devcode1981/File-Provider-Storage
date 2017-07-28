# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

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

    case ARGV.shift
    when 'run'
      exec('./run', *ARGV, chdir: $gdk_root)
    when 'install'
      exec(MAKE, *ARGV, chdir: $gdk_root)
    when 'update'
      exec(MAKE, 'update', chdir: $gdk_root)
    when 'reconfigure'
      remember!($gdk_root)
      exec(MAKE, 'clean-config', 'unlock-dependency-installers', 'all', chdir: $gdk_root)
    when 'psql'
      exec('psql', '-h', File.join($gdk_root, 'postgresql'), *ARGV, chdir: $gdk_root)
    when 'redis-cli'
      exec('redis-cli', '-s', File.join($gdk_root, 'redis/redis.socket'), *ARGV, chdir: $gdk_root)
    when 'help'
      puts File.read(File.join($gdk_root, 'HELP'))
      true
    else
      puts "Usage: #{PROGNAME} run|init|install|update|reconfigure|psql|redis-cli|version|help [ARGS...]"
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
