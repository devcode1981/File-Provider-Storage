require 'open3'

class Shellout
  attr_reader :args, :opts

  def initialize(args, **opts)
    @args = args
    @opts = opts
  end

  def run
    capture
    read_stdout
  end

  def try_run
    capture(err: '/dev/null')
    read_stdout
  rescue Errno::ENOENT
    ''
  end

  def read_stdout
    @stdout_str.chomp
  end

  def read_stderr
    @stderr_str.chomp
  end

  def success?
    @status.success?
  end

  private

  def capture(extra_options = {})
    @stdout_str, @stderr_str, @status = Open3.capture3(*args, opts.merge(extra_options))
  end
end
