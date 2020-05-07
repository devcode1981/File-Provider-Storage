require 'open3'
require_relative 'config'
require_relative '../shellout'
require_relative 'output'

module GDK
  class PostgreSQL
    def ready?
      last_error = nil

      # The '' is very important here so need to keep this cop disabled
      cmd = psql_cmd + %W[-d template1 -c #{''}] # rubocop:disable Lint/LiteralInInterpolation
      10.times do
        shellout = Shellout.new(cmd)
        shellout.run
        last_error = shellout.read_stderr

        return true if shellout.success?

        sleep 1
      end

      GDK::Output.error last_error
      false
    end

    def db_exists?(dbname)
      system(*(psql_cmd + ['-d', dbname, '-c', '']), err: '/dev/null')
    end

    def createdb(args)
      cmd = [File.join(config.bin_dir, 'createdb'), '-h', host, '-p', port] + args
      system(*cmd)
    end

    private

    def config
      @config ||= GDK::Config.new.postgresql
    end

    def host
      config.dir.to_s
    end

    def port
      config.port.to_s
    end

    def psql_cmd
      [File.join(config.bin_dir, 'psql'), '-h', host, '-p', port]
    end
  end
end
