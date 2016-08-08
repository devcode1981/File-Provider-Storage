GDK_ROOT = ENV.delete('GDK_ROOT').to_s
PROGNAME = ENV.delete('GDK_INVOKED').to_s

def main
  case ARGV.shift
  when 'run'
    system('./run', *ARGV, chdir: GDK_ROOT)
  when 'install'
    system('make', *ARGV, chdir: GDK_ROOT)
  when 'update'
    system('make', 'update', chdir: GDK_ROOT)
  when 'reconfigure'
    system('make', 'clean-config', 'all', chdir: GDK_ROOT)
  when 'help'
    puts File.read(File.join(GDK_ROOT, 'HELP')).gsub(/^\.\/gdk/, PROGNAME)
    true
  else
    puts "Usage: #{PROGNAME} run|install|update|reconfigure|help [ARGS...]"
    false
  end
end

exit main

