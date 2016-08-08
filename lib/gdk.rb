module GDK
  PROGNAME = 'gdk'

  def self.main
    case ARGV.shift
    when 'run'
      system('./run', *ARGV, chdir: $gdk_root)
    when 'install'
      system('make', *ARGV, chdir: $gdk_root)
    when 'update'
      system('make', 'update', chdir: $gdk_root)
    when 'reconfigure'
      system('make', 'clean-config', 'all', chdir: $gdk_root)
    when 'help'
      puts File.read(File.join($gdk_root, 'HELP'))
      true
    else
      puts "Usage: #{PROGNAME} run|init|install|update|reconfigure|help [ARGS...]"
      false
    end
  end
end
