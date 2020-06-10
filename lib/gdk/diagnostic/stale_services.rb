# frozen_string_literal: true

module GDK
  module Diagnostic
    class StaleServices < Base
      TITLE = 'Stale Services'

      def diagnose
        ps_command.try_run

        nil
      end

      def success?
        return true unless ps_command.success?

        stale_processes.empty?
      end

      def detail
        return stale_services_detail unless success?
      end

      private

      StaleProcess = Struct.new(:pid, :service)

      def ps_command
        @ps_command ||= begin
          joined_service_mames = service_names.join('|')
          Shellout.new(%(pgrep -l -P 1 -f "runsv (#{joined_service_mames})"))
        end
      end

      def service_names
        %w[
          elasticsearch
          geo-cursor
          gitaly
          gitlab-pages
          gitlab-workhorse
          grafana
          jaeger
          mattermost
          minio
          nginx
          openldap
          postgresql
          praefect
          prometheus
          registry
          rails-actioncable
          rails-background-jobs
          rails-web
          redis
          runner
          sshd
          tunnel_
          webpack
        ]
      end

      def stale_processes
        @stale_processes ||= begin
          return [] unless ps_command.success?

          ps_command.read_stdout.split("\n").each_with_object([]) do |process, all|
            m = process.match(/^(?<pid>\d+) +runsv (?<service>.+)$/)
            next unless m

            all << StaleProcess.new(m[:pid], m[:service])
          end
        end
      end

      def stale_services_detail
        return if success?

        stale_services = stale_processes.map(&:service).join("\n")
        stale_pids = stale_processes.map(&:pid).join(' ')

        <<~MESSAGE
          The following GDK services appear to be stale:

          #{stale_services}

          You can try killing them by running:

          kill #{stale_pids}
        MESSAGE
      end
    end
  end
end
