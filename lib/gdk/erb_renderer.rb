# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'

module GDK
  class ErbRenderer
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

      return FileUtils.mv(temp_file.path, target) unless File.exist?(target)

      warn!(temp_file) unless FileUtils.identical?(target, temp_file.path)
    ensure
      temp_file.close!
    end

    private

    def warn!(temp_file)
      diff = `git --no-pager diff --no-index #{colors_arg} -u "#{target}" "#{temp_file.path}"`

      puts <<~EOF
        -------------------------------------------------------------------------------------------------------------
        Warning: Your `#{target}` is outdated. These are the changes GDK wanted to apply.
        -------------------------------------------------------------------------------------------------------------
        #{diff}
        -------------------------------------------------------------------------------------------------------------
        - To apply these changes run: `rm #{target}` and re-run `gdk update`.
        - To silence this warning (at your own peril): `touch #{target}`
        ... Waiting 5 seconds for previous warning to be noticed.
        -------------------------------------------------------------------------------------------------------------
      EOF
      sleep 5
    end

    def colors?
      @colors_supported ||= (`tput colors`.chomp.to_i >= 8)
    end

    def colors_arg
      '--color' if colors?
    end
  end
end
