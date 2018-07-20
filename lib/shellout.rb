class Shellout
  attr_reader :args

  def initialize(args)
    @args = args
  end

  def run
    popen_read
  end

  def try_run
    popen_read(err: '/dev/null')
  rescue Errno::ENOENT
    ''
  end

  private

  def popen_read(options = {})
    IO.popen(args, options, &:read).chomp
  end
end
