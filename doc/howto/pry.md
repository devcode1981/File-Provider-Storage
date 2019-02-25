# Debugging with Pry

[Pry](https://pryrepl.org/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop in the magic word `binding.pry`.

When running tests Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec`
etc.).

If you want to get a debugging prompt while browsing on your local
development server (localhost:3000) you need to comment out the
`rails-web:` line in the Procfile in your GDK root directory because
Unicorn is not compatible with Pry.

You can also run `make pry` to make this change for you.  `make pry-off`
will revert back to the original configuration.

Then launch GDK as usual (e.g. with `gdk run`) and in a separate
terminal run: `gdk run thin`. Your Pry prompts will appear in the window
that runs Thin.

**Note**: It's not possible to submit commits from the web without at least two `unicorn` servers running.  Which means when running `thin` for debugging, actions such as creating a file from the web will time out. See [Use GitLab with only 1 Unicorn worker?](https://gitlab.com/gitlab-org/gitlab-ce/issues/18771)
