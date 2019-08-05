require_relative 'gdk/config'

def main(argv)
  applications = applications_from(argv)
  print_url if print_url?(applications)
  foreman_exec(applications)
end

def applications_from(argv)
  exec_thin! if argv[0] == 'thin'

  return %w[all] if argv.empty?

  argv.each_with_object([]) do |command, all|
    all << applications_for(command)
  end.flatten.uniq
end

def exec_thin!
  exec(
    { 'RAILS_ENV' => 'development' },
    *%W[bundle exec thin --socket=#{Dir.pwd}/gitlab.socket start],
    chdir: 'gitlab'
  )
end

def praefect_services
  @config ||= GDK::Config.new
  services = %w[praefect]
  @config.praefect.nodes.each_with_index {|praefect_node, index| services.push("praefect-gitaly-#{index}") }
  services
end

def applications_for(command)
  case command
  when 'db'
    %w[redis postgresql openldap influxdb webpack registry minio elasticsearch jaeger]
  when 'geo_db'
    %w[postgresql-geo]
  when 'app'
    %w[gitlab-workhorse nginx grafana sshd gitaly storage-check gitlab-pages rails-web rails-background-jobs]
  when 'grafana'
    %w[grafana]
  when 'gitaly'
    %w[gitaly]
  when 'praefect'
    praefect_services
  when 'jobs'
    %w[rails-background-jobs]
  else
    puts
    puts "GitLab Development Kit does not recognize command '#{command}'."
    puts "Make sure you are using the latest version or check available commands with: \`gdk help\` "
    puts
    exit 1
  end
end

def foreman_exec(svcs = [], exclude: [])
  args = %w[ruby lib/daemonizer.rb foreman start]

  unless svcs.empty? && exclude.empty?
    args << '-m'
    svc_string = ['all=0', svcs.map { |svc| svc + '=1' }, exclude.map { |svc| svc + '=0' }].join(',')
    args << svc_string
  end

  exec({
    'GITLAB_TRACING' => 'opentracing://jaeger?http_endpoint=http%3A%2F%2Flocalhost%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1',
    'GITLAB_TRACING_URL' => 'http://localhost:16686/search?service={{ service }}&tags=%7B"correlation_id"%3A"{{ correlation_id }}"%7D'
  }, *args)
end

def print_logo
  printf "

           \033[38;5;88m\`                        \`
          :s:                      :s:
         \`oso\`                    \`oso.
         +sss+                    +sss+
        :sssss:                  -sssss:
       \`ossssso\`                \`ossssso\`
       +sssssss+                +sssssss+
      -ooooooooo-++++++++++++++-ooooooooo-
     \033[38;5;208m\`:/\033[38;5;202m+++++++++\033[38;5;88mosssssssssssso\033[38;5;202m+++++++++\033[38;5;208m/:\`
     -///\033[38;5;202m+++++++++\033[38;5;88mssssssssssss\033[38;5;202m+++++++++\033[38;5;208m///-
    .//////\033[38;5;202m+++++++\033[38;5;88mosssssssssso\033[38;5;202m+++++++\033[38;5;208m//////.
    :///////\033[38;5;202m+++++++\033[38;5;88mosssssssso\033[38;5;202m+++++++\033[38;5;208m///////:
     .:///////\033[38;5;202m++++++\033[38;5;88mssssssss\033[38;5;202m++++++\033[38;5;208m///////:.\`
       \`-://///\033[38;5;202m+++++\033[38;5;88mosssssso\033[38;5;202m+++++\033[38;5;208m/////:-\`
          \`-:////\033[38;5;202m++++\033[38;5;88mosssso\033[38;5;202m++++\033[38;5;208m////:-\`
             .-:///\033[38;5;202m++\033[38;5;88mosssso\033[38;5;202m++\033[38;5;208m///:-.
               \`.://\033[38;5;202m++\033[38;5;88mosso\033[38;5;202m++\033[38;5;208m//:.\`
                  \`-:/\033[38;5;202m+\033[38;5;88moo\033[38;5;202m+\033[38;5;208m/:-\`
                     \`-++-\`\033[0m

  "
  puts
end

def print_url
  print_logo
  puts
  puts "Starting GitLab in #{Dir.pwd} on http://#{ENV['host']}:#{ENV['port']}#{ENV['relative_url_root']}"
  puts
  puts
end

def print_url?(applications)
  (applications & ['gitlab-workhorse', 'all']).any?
end

main(ARGV)
