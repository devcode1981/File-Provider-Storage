# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DiffConfig
      def run(stdout: $stdout, stderr: $stderr)
        files = %w[
          .ruby-version
          Procfile
          gitaly/gitaly.config.toml
          gitaly/praefect.config.toml
          gitlab-runner-config.toml
          gitlab-shell/.gitlab_shell_secret
          gitlab-shell/config.yml
          gitlab-workhorse/config.toml
          gitlab/config/cable.yml
          gitlab/config/database.yml
          gitlab/config/database_geo.yml
          gitlab/config/gitlab.yml
          gitlab/config/puma.rb
          gitlab/config/resque.yml
          gitlab/config/unicorn.rb
          nginx/conf/nginx.conf
          redis/redis.conf
          registry/config.yml
        ]

        file_diffs = files.map do |file|
          ConfigDiff.new(file)
        end

        # Iterate over each file from files Array and print any output to
        # stderr that may have come from running `make <file>`.
        #
        file_diffs.each do |diff|
          output = diff.make_output.to_s.chomp
          next if output.empty?

          stderr.puts(output)
        end

        # Iterate over each file from files Array and print any output to
        # stdout that may have come from running `git diff <file>.unchanged`
        # which is how we know what _would_ happen if we ran `gdk reconfigure`
        #
        file_diffs.each do |diff|
          next if diff.output.to_s.empty?

          stdout.puts(diff.output)
        end
      end

      class ConfigDiff
        attr_reader :file, :output, :make_output

        def initialize(file)
          @file = file

          execute
        end

        def file_path
          @file_path ||= GDK.root.join(file)
        end

        private

        def execute
          # It's entirely possible file_path doesn't exist because it may be
          # a config file that user does not need and therefore has not been
          # generated.
          return nil unless file_path.exist?

          File.rename(file_path, file_path_unchanged)

          @make_output = update_config_file

          @output = diff_with_unchanged
        ensure
          File.rename(file_path_unchanged, file_path) if File.exist?(file_path_unchanged)
        end

        def file_path_unchanged
          @file_path_unchanged ||= "#{file_path}.unchanged"
        end

        def update_config_file
          run(GDK::MAKE, file)
        end

        def diff_with_unchanged
          run('git', 'diff', '--no-index', '--color', "#{file}.unchanged", file)
        end

        def run(*commands)
          IO.popen(commands.join(' '), chdir: GDK.root, &:read).chomp
        end
      end
    end
  end
end
