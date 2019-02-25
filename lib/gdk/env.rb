require 'pathname'
require 'shellwords'

module GDK
  module Env
    class << self
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
        env.each do |k, v|
          puts "export #{Shellwords.shellescape(k)}=#{Shellwords.shellescape(v)}"
        end
      end

      def exec_env(argv)
        # Use Kernel:: namespace to avoid recursive method call
        Kernel::exec(env, *argv)
      end

      def env
        case get_project
        when 'gitaly'
          { 'GOPATH' => File.join($gdk_root, 'gitaly') }
        when 'gitlab-workhorse'
          { 'GOPATH' => File.join($gdk_root, 'gitlab-workhorse') }
        when 'gitlab-shell', 'go-gitlab-shell'
          { 'GOPATH' => File.join($gdk_root, 'go-gitlab-shell') }
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
end
