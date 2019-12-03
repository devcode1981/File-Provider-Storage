# frozen_string_literal: true

require_relative '../../config_diff'

module GDK
  module Command
    class DiffConfig
      def run(stdout: $stdout, stderr: $stderr)
        files = %w[
          gitlab/config/gitlab.yml
          gitlab/config/database.yml
          gitlab/config/unicorn.rb
          gitlab/config/puma.rb
          gitlab/config/resque.yml
          gitlab-shell/config.yml
          gitlab-shell/.gitlab_shell_secret
          redis/redis.conf
          .ruby-version
          Procfile
          gitlab-workhorse/config.toml
          gitaly/gitaly.config.toml
          gitaly/praefect.config.toml
          nginx/conf/nginx.conf
        ]

        file_diffs = files.map do |file|
          ConfigDiff.new(file)
        end

        file_diffs.each do |diff|
          stderr.puts diff.make_output
        end

        file_diffs.each do |diff|
          stdout.puts diff.output unless diff.output == ""
        end
      end
    end
  end
end

