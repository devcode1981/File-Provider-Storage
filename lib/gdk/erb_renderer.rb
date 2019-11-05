# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'

require_relative '../shellout'

module GDK
  class ErbRenderer
    BACKUP_DIR = '.backups'

    attr_reader :source, :target

    def initialize(source, target, args = {})
      @source = source
      @target = target
      @args = args
    end

    def render!(target = @target)
      str = File.read(source)
      # A trim_mode of '-' allows omitting empty lines with <%- -%>
      result = ERB.new(str, trim_mode: '-').result_with_hash(@args)

      File.write(target, result)
    end

    def safe_render!
      temp_file = Tempfile.open(target)
      render!(temp_file.path)

      if File.exist?(target)
        return if FileUtils.identical?(target, temp_file.path)

        warn_changes!(temp_file.path)

        if config.gdk.overwrite_changes
          backup!

          warn_overwritten!
          wait!
        else
          warn_not_applied!
          wait!

          return
        end
      end

      FileUtils.mv(temp_file.path, target)
    ensure
      temp_file.close
    end

    private

    def warn_changes!(temp_file)
      diff = Shellout.new(%W[git --no-pager diff --no-index #{colors_arg} -u #{target} #{temp_file}]).run

      puts <<~EOF
        -------------------------------------------------------------------------------------------------------------
        Warning: Your '#{target}' contains changes. Here is the diff:
        -------------------------------------------------------------------------------------------------------------
        #{diff}
        -------------------------------------------------------------------------------------------------------------
      EOF
    end

    def warn_not_applied!
      puts <<~EOF
        The changes have not been applied.
        - To apply these changes, run:
          rm #{target} && make #{target}
        - To silence this warning (at your own peril):
          touch #{target}
        -------------------------------------------------------------------------------------------------------------
      EOF
    end

    def warn_overwritten!
      puts <<~EOF
        '#{target}' bas been overwritten. To recover the previous version, run:
          cp -f '#{backup_file}' '#{target}'
        -------------------------------------------------------------------------------------------------------------
      EOF
    end

    def wait!
      puts <<~EOF
        ... Waiting 5 seconds for previous warning to be noticed.
      EOF

      sleep 5
    end

    def backup!
      FileUtils.mkdir_p(BACKUP_DIR)
      FileUtils.mv(target, backup_file)
    end

    def colors?
      @colors_supported ||= (`tput colors`.chomp.to_i >= 8)
    end

    def colors_arg
      '--color' if colors?
    end

    def backup_file
      @backup_file ||=
        File.join(BACKUP_DIR,
                  target.gsub('/', '__').concat('.', Time.now.strftime('%Y%m%d%H%M%S')))
    end

    def config
      @args[:config] || raise(::ArgumentError, "'args' argument should have ':config' key")
    end
  end
end
