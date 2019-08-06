#!/usr/bin/env ruby
require_relative 'shellout'
require_relative 'runit/config'

module Runit
  def self.start_runsvdir
    Dir.chdir($gdk_root)

    Runit::Config.new($gdk_root).render

    # It is important that we use an absolute path with `runsvdir`: this
    # allows us to distinguish processes belonging to different GDK
    # installations on the same machine.
    args = ['runsvdir', '-P', File.join($gdk_root, 'services')]
    return if runsvdir_running?(args.join(' '))

    Process.fork do
      Dir.chdir('/')
      Process.setsid

      # Cargo-culting the use of 395 periods from omnibus-gitlab.
      # https://gitlab.com/gitlab-org/omnibus-gitlab/blob/5dfdcafa30ad6e203a04a917f180b630d5121cf6/config/templates/runit/runsvdir-start.erb#L42
      spawn(*args, 'log: ' + '.' * 395, in: '/dev/null', out: '/dev/null', err: '/dev/null')
    end
  end

  def self.runsvdir_running?(cmd)
    pgrep = Shellout.new(%w[pgrep runsvdir]).run
    return if pgrep.empty?

    pids = pgrep.split("\n").map { |str| Integer(str) }
    pids.any? do |pid|
      Shellout.new(%W[ps -o args= -p #{pid}]).run.start_with?(cmd + ' ')
    end
  end

  def self.sv(cmd, services)
    Dir.chdir($gdk_root)
    start_runsvdir
    services = service_args(services)
    services.each { |svc| wait_runsv!(svc) }
    exec('sv', cmd, *services)
  end

  def self.service_args(services)
    return Dir['./services/*'].sort if services.empty?

    services.flat_map do |svc|
      if svc == 'rails'
        Dir['./services/rails-*'].sort
      else
        File.join('./services', svc)
      end
    end
  end

  def self.wait_runsv!(dir)
    abort "unknown runit service: #{dir}" unless File.directory?(dir)

    50.times do
      open(File.join(dir, 'supervise/ok'), File::WRONLY|File::NONBLOCK).close
      return
    rescue
      sleep 0.1
    end

    abort "timeout waiting for runsv in #{dir}"
  end

  def self.tail(services)
    Dir.chdir($gdk_root)

    tails = log_files(services).map { |log| spawn('tail', '-f', log) }

    %w[INT TERM].each do |sig|
      trap(sig) { kill_processes(tails) }
    end

    wait = Thread.new { sleep }
    tails.each do |tail|
      Thread.new do
        Process.wait(tail)
        wait.kill
      end
    end

    wait.join
    kill_processes(tails)
    exit
  end

  def self.log_files(services)
    return Dir['log/*/current'] if services.empty?

    services.flat_map do |svc|
      if svc == 'rails'
        Dir['./log/rails-*/current']
      else
        File.join('log', svc, 'current')
      end
    end
  end

  def self.kill_processes(pids)
    pids.each do |pid|
      begin
        Process.kill('TERM', pid)
      rescue Errno::ESRCH
      end
    end
  end
end
