# Debugging with Pry

[Pry](http://pryrepl.org/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop in the magic word `binding.pry`.

When running tests Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec`
etc.).

If you want to get a debugging prompt while browsing on your local
development server (localhost:3000) you need to make a change to the
Procfile in your GDK root directory because Unicorn is not compatible
with Pry.

There are two `rails-web` lines in the Procfile, one containing
`bin/web` and one containing `thin`. Comment out the line containing
`bin/web` and uncomment the line containing `thin`. Now when you start
GDK with `./run` or `./run app` the Rails web application runs in Thin
instead of Unicorn.
