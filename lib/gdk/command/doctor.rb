# frozen_string_literal: true

require 'thread'

module GDK
  module Command
    class Doctor
      def initialize(diagnostics: GDK::Diagnostic.all, stdout: $stdout, stderr: $stderr)
        @diagnostics = diagnostics
        @stdout = stdout
        @stderr = stderr
      end

      def run
        start_necessary_services

        if diagnostic_results.empty?
          show_healthy
        else
          show_results
        end
      end

      private

      attr_reader :diagnostics, :stdout, :stderr

      def diagnostic_results
        @diagnostic_results ||= jobs.map { |x| x.join[:results] }.compact
      end

      def jobs
        diagnostics.map do |diagnostic|
          Thread.new do
            Thread.current[:results] = perform_diagnosis_for(diagnostic)
          end
        end
      end

      def perform_diagnosis_for(diagnostic)
        diagnostic.diagnose
        diagnostic.message unless diagnostic.success?
      end

      def start_necessary_services
        Shellout.new('gdk start postgresql').run
      end

      def show_healthy
        stdout.puts 'GDK is healthy.'
      end

      def show_results
        stdout.puts warning
        diagnostic_results.each do |result|
          stdout.puts result
        end
      end

      def warning
        <<~WARNING
          #{'=' * 80}
          Please note these warning only exist for debugging purposes and can
          help you when you encounter issues with GDK.
          If your GDK is working fine, you can safely ignore them. Thanks!
          #{'=' * 80}

        WARNING
      end
    end
  end
end
