# frozen_string_literal: true

$LOAD_PATH.unshift('.')

require 'lib/gdk/config'

def config
  @config ||= GDK::Config.new
end

def render_erb(source, target)
  str = File.read(source)
  result = ERB.new(str).result

  IO.write(target, result)
end

file 'Procfile' => ['Procfile.erb', 'gdk.yml', 'gdk-defaults.yml'] do |t|
  render_erb(t.source, t.name)
end

file 'nginx/conf/nginx.conf' => ['nginx/conf/nginx.conf.erb', 'gdk.yml', 'gdk-defaults.yml'] do |t|
  render_erb(t.source, t.name)
end
