# frozen_string_literal: true

$LOAD_PATH.unshift('.')

require 'lib/gdk'
require 'rake/clean'

CONFIGS = FileList['Procfile', 'nginx/conf/nginx.conf', 'gitlab/config/gitlab.yml']
CLOBBER.include *CONFIGS, 'gdk.example.yml'

def config
  @config ||= GDK::Config.new
end

desc 'Dump the configured settings'
task 'dump_config' do
  GDK::Config.new.dump!(STDOUT)
end

desc 'Generate an example config file with all the defaults'
file 'gdk.example.yml' => 'clobber:gdk.example.yml' do |t|
  File.open(t.name, File::CREAT|File::TRUNC|File::WRONLY) do |file|
    config = Class.new(GDK::Config)
    config.define_method(:gdk_root) { '/home/git/gdk' }
    config.define_method(:username) { 'git' }
    config.define_method(:read!) { |_| nil }

    config.new(yaml: {}).dump!(file)
  end
end

desc 'Regenerate all config files from scratch'
task reconfigure: [:clobber, :all]

desc 'Generate all config files'
task all: CONFIGS

task 'clobber:gdk.example.yml' do |t|
  Rake::Cleaner.cleanup_files([t.name])
end

desc 'Generate Procfile for Foreman'
file 'Procfile' => ['Procfile.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name).safe_render!
end

desc 'Generate nginx configuration'
file 'nginx/conf/nginx.conf' => ['nginx/conf/nginx.conf.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name).safe_render!
end

desc 'Generate the gitlab.yml config file'
file 'gitlab/config/gitlab.yml' => ['support/templates/gitlab.yml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name).render!
end

desc 'Generate Gitaly config toml'
file 'gitaly/gitaly.config.toml' => ['support/templates/gitaly.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name).render!
end

desc 'Generate Praefects config toml'
file 'gitaly/praefect.config.toml' => ['support/templates/praefect.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name).render!
end

namespace :praefect do
  PRAEFECT_ENABLED_PATH = 'praefect_enabled'

  desc 'Enable praefect and configure it to run'
  task :enable => 'gitaly/praefect.config.toml' do
    File.write(PRAEFECT_ENABLED_PATH, 'true')
    Rake::Task[:reconfigure].invoke
  end

  desc 'Disable praefect and do not run it'
  task :disable do
    File.delete(PRAEFECT_ENABLED_PATH)
    Rake::Task[:reconfigure].invoke
  end
end
