# frozen_string_literal: true

require 'open3'

class Shellout
  attr_reader :args, :opts

  def initialize(*args, **opts)
    @args = args.flatten
    @opts = opts
    @stdout_str = ''
    @stderr_str = ''
  end

  def stream
    popen do |stdout, stderr|
      if stderr
        @stderr_str += stderr.to_s
        $stderr.print(stderr)
      end

      if stdout
        @stdout_str += stdout.to_s
        $stdout.print(stdout)
      end
    end

    @stdout_str
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

  def popen
    # Source: https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    Open3.popen3(*args) do |_, stdout, stderr, thread|
      { out: stdout, err: stderr }.each do |key, stream|
        Thread.new do
          until (line = stream.gets).nil?
            if block_given?
              if key == :out
                yield line, nil
              else
                yield nil, line
              end
            end
          end
        end
      end

      thread.join
      @status = thread.value
    end
  end
end
