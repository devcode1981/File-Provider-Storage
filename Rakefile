# frozen_string_literal: true

$LOAD_PATH.unshift('.')

require 'lib/gdk'

def config
  @config ||= GDK::Config.new
end

file 'Procfile' => ['Procfile.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name).safe_render!
end

file 'nginx/conf/nginx.conf' => ['nginx/conf/nginx.conf.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name).safe_render!
end
