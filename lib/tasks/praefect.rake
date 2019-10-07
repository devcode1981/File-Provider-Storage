namespace :praefect do
  PRAEFECT_ENABLED_PATH = 'praefect_enabled'

  desc 'Generate praefect configs'
  task :configs do
    Rake::Task['gitaly/praefect.config.toml'].invoke
    config.praefect.nodes.each_with_index do |node, index|
      Rake::Task["gitaly/gitaly-#{index}.praefect.toml"].invoke
    end
  end

  desc 'Enable praefect and configure it to run'
  task :enable => 'gitaly/praefect.config.toml' do
    File.write(PRAEFECT_ENABLED_PATH, 'true')
    Rake::Task['praefect:configs'].invoke
    Rake::Task['reconfigure'].invoke
  end

  desc 'Disable praefect and do not run it'
  task :disable do
    File.delete(PRAEFECT_ENABLED_PATH)
    Rake::Task['reconfigure'].invoke
  end
end
