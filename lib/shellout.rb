# frozen_string_literal: true

require 'open3'

class Shellout
  attr_reader :args, :opts

  def initialize(*args, **opts)
    @args = args.flatten
    @opts = opts
  end

  def stream(extra_options = {})
    @stdout_str = ''
    @stderr_str = ''

    # Inspiration: https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    Open3.popen3(*args, opts.merge(extra_options)) do |_stdin, stdout, stderr, thread|
      threads = Array(thread)
      threads << thread_read(stdout, method(:print_out))
      threads << thread_read(stderr, method(:print_err))

      threads.each(&:join)

      @status = thread.value
    end

    read_stdout
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
    return false unless @status

    @status.success?
  end

  private

  def capture(extra_options = {})
    @stdout_str, @stderr_str, @status = Open3.capture3(*args, opts.merge(extra_options))
  end

  def thread_read(io, meth)
    Thread.new do
      io.each_line { |line| meth.call(line) }
    end
  end

  def print_out(msg)
    @stdout_str += msg
    $stdout.print(msg)
  end

  def print_err(msg)
    @stderr_str += msg
    $stderr.print(msg)
  end
end
