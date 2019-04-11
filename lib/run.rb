def main(argv)
  case argv[0]
  when 'db'
    foreman_exec(%w[redis postgresql openldap influxdb webpack registry minio elasticsearch jaeger])
  when 'geo_db'
    foreman_exec(%w[postgresql-geo])
  when 'app'
    svcs = %w[gitlab-workhorse nginx grafana sshd gitaly storage-check gitlab-pages]

    foreman_exec(svcs + %w[rails-web rails-background-jobs])
  when 'grafana'
    foreman_exec(%w[grafana])
  when 'thin'
    exec(
      { 'RAILS_ENV' => 'development' },
      *%W[bundle exec thin --socket=#{Dir.pwd}/gitlab.socket start],
      chdir: 'gitlab'
    )
  when 'gitaly'
    foreman_exec(%w[gitaly])
  when 'jobs'
    foreman_exec(%w[rails-background-jobs])
  when nil
    print_url
    foreman_exec(%w[all])
  else
    puts
    puts "GitLab Development Kit does not recognize this command."
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

main(ARGV)
