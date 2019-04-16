def main
  daemon_pid = daemonize(ARGV)
  trap('INT') { trigger_normal_shutdown(daemon_pid) }

  loop do
    break unless pid_running?(daemon_pid)
    sleep 1
  end
end

# daemonize does a standard double fork, with an added twist: a
# separate process that monitors both the original process and the
# daemon process, and terminates the other if one disappears.
def daemonize(args)
  top_pid = Process.pid

  pipe_read, pipe_write = IO.pipe

  middle_pid = Process.fork
  if middle_pid
    # This if-branch is in the top process.
    pipe_write.close

    daemon_pid = pipe_read.read.to_i
    pipe_read.close

    Process.wait(middle_pid)

    return daemon_pid
  end

  pipe_read.close

  STDIN.reopen '/dev/null'

  # Become session leader (standard part of daemonizing).
  Process.setsid

  daemon_pid = Process.fork
  unless daemon_pid
    # This is the daemon process.

    pipe_write.close
    exec(*args)

    # This line is never reached.
  end

  # Still in the middle process.
  pipe_write.write(daemon_pid.to_s)
  pipe_write.close

  Process.fork do
    # This is our watchdog
    watch_pids(top_pid, daemon_pid)
    exit
  end

  # The middle process is only used during startup.
  exit
end

def pid_running?(pid)
  Process.kill(0, pid)
  true
rescue Errno::ESRCH
  false
end

def watch_pids(pid1, pid2)
  loop do
    unless pid_running?(pid1)
      trigger_normal_shutdown(pid2)
      return
    end

    unless pid_running?(pid2)
      trigger_normal_shutdown(pid1)
      return
    end

    sleep 1
  end
end

def trigger_normal_shutdown(pid)
  Process.kill('TERM', pid)
rescue Errno::ESRCH
  # pid is already gone
end

main
