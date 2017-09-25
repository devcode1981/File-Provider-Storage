require 'fileutils'

class ConfigDiff
  attr_reader :file, :output, :make_output

  def initialize(file)
    @file = file

    execute
  end

  def file_path
    @file_path ||= File.join($gdk_root, file)
  end

  private

  def execute
    FileUtils.mv(file_path, "#{file_path}.unchanged")

    @make_output = update_config_file

    @output = diff_with_unchanged
  ensure
    File.rename("#{file_path}.unchanged", file_path)
  end

  def update_config_file
    run(GDK::MAKE, file)
  end

  def diff_with_unchanged
    run('git', 'diff', '--no-index', '--color', "#{file}.unchanged", file)
  end

  def run(*commands)
    IO.popen(commands.join(' '), chdir: $gdk_root, &:read).chomp
  end
end
