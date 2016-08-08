# Debugging with Pry

[Pry](http://pryrepl.org/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop in the magic word `binding.pry`.

When running tests Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec`
etc.).

If you want to get a debugging prompt while browsing on your local
development server (localhost:3000) you need to comment out the
`rails-web:` line in the Procfile in your GDK root directory because
Unicorn is not compatible with Pry.

Then launch GDK as usual (e.g. with `gdk run`) and in a separate
terminal run: `gdk run thin`. Your Pry prompts will appear in the window
that runs Thin.
