require 'pathname'
require 'shellwords'

module GDK
  class Env
    def self.exec(argv)
      new.exec(argv)
    end
    
    def exec(argv)
      if argv.empty?
        print_env
        exit
      else
        exec_env(argv)
      end
    end

    private

    def print_env
      env(get_project).each do |k, v|
        puts "export #{Shellwords.shellescape(k)}=#{Shellwords.shellescape(v)}"
      end
    end
    
    def exec_env(argv)
      Kernel::exec(env(get_project), *argv)
    end
    
    def env(project)
      case project
      when 'gitaly'
        { 'GOPATH' => File.join($gdk_root, project) }
      when 'gitlab-workhorse'
        { 'GOPATH' => File.join($gdk_root, project) }
      else
        {}
      end
    end
    
    def get_project
      relative_path = Pathname.new(Dir.pwd).relative_path_from(Pathname.new($gdk_root)).to_s
      relative_path.split('/').first
    end
  end
end
