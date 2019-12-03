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
  File.open(t.name, File::CREAT | File::TRUNC | File::WRONLY) do |file|
    config = Class.new(GDK::Config)
    config.define_method(:gdk_root) { Pathname.new('/home/git/gdk') }
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

file GDK::Config::FILE do |t|
  FileUtils.touch(t.name)
end

desc 'Generate Procfile that defines the list of services to start'
file 'Procfile' => ['Procfile.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).render!
end

# Define as a task instead of a file, so it's built unconditionally
task 'gdk-config.mk' => 'gdk-config.mk.erb' do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).render!
  puts t.name # Print the filename, so make can include it
end

desc 'Generate nginx configuration'
file 'nginx/conf/nginx.conf' => ['nginx/conf/nginx.conf.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).safe_render!
end

desc 'Generate sshd configuration'
file 'openssh/sshd_config' => ['openssh/sshd_config.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).safe_render!
end

desc 'Generate the database.yml config file'
file 'gitlab/config/database.yml' => ['support/templates/database.yml.erb', GDK::Config::FILE] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).safe_render!
end

desc 'Generate the gitlab.yml config file'
file 'gitlab/config/gitlab.yml' => ['support/templates/gitlab.yml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).safe_render!
end

desc "Generate gitaly config toml"
file "gitaly/gitaly.config.toml" => ['support/templates/gitaly.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(
    t.source,
    t.name,
    config: config,
    path: config.repositories_root,
    storage: 'default',
    socket_path: config.gitaly.address,
    log_dir: config.gitaly.log_dir,
    internal_socket_dir: config.gitaly.internal_socket_dir
  ).render!
  FileUtils.mkdir_p(config.repositories_root)
  FileUtils.mkdir_p(config.gitaly.log_dir)
end

file 'gitaly/praefect.config.toml' => ['support/templates/praefect.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).render!

  config.praefect.nodes.each_with_index do |node, index|
    Rake::Task[node['config_file']].invoke
  end

  FileUtils.mkdir_p(config.praefect.internal_socket_dir)
end

config.praefect.nodes.each do |node|
  desc "Generate gitaly config for #{node['storage']}"
  file node['config_file'] => ['support/templates/gitaly.config.toml.erb'] do |t|
    GDK::ErbRenderer.new(
      t.source,
      t.name,
      config: config,
      path: node['storage_dir'],
      storage: node['storage'],
      log_dir: node['log_dir'],
      socket_path: node['address'],
      internal_socket_dir: config.praefect.internal_socket_dir
    ).render!
    FileUtils.mkdir_p(node['storage_dir'])
    FileUtils.mkdir_p(node['log_dir'])
  end
end
