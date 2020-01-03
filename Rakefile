# frozen_string_literal: true

$LOAD_PATH.unshift('.')

require 'fileutils'
require 'lib/gdk'
require 'lib/git/configure'
require 'rake/clean'

Rake.add_rakelib 'lib/tasks'

desc 'Preflight checks for dependencies'
task 'preflight-checks' do
  checker = GDK::Dependencies::Checker.new
  checker.check_all

  if !checker.error_messages.empty?
    warn checker.error_messages
    exit 1
  end
end
