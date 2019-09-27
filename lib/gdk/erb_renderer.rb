# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'

module GDK
  class ErbRenderer
    BACKUP_DIR = '.bak'

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
      temp_file = Tempfile.new(target)

      render!(temp_file.path)

      has_changes = File.exist?(target) && !FileUtils.identical?(target, temp_file.path)

      backup! if has_changes

      FileUtils.mv(temp_file.path, target)

      warn_changes! if has_changes
    ensure
      temp_file.close!
    end

    private

    def warn_changes!
      diff = `git --no-pager diff --no-index #{colors_arg} -u "#{backup_file}" "#{target}"`

      puts <<~EOF
        -------------------------------------------------------------------------------------------------------------
        Warning: Your '#{target}' is overwritten. These are the changes GDK has made.
        -------------------------------------------------------------------------------------------------------------
        #{diff}
        -------------------------------------------------------------------------------------------------------------
        To recover the old file run:
          cp -f '#{backup_file}' '#{target}'
        ... Waiting 5 seconds for previous warning to be noticed.
        -------------------------------------------------------------------------------------------------------------
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
  end
end
