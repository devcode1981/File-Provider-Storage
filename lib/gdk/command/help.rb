# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class Help
      def run(stdout: $stdout, stderr: $stderr)
        GDK::Logo.print
        stdout.puts File.read(File.join(GDK.root, 'HELP'))
      end
    end
  end
end
