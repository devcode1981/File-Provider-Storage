# Debugging with Pry

[Pry](https://pryrepl.org/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop in the magic word `binding.pry`.

When running tests Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec`
etc.).

If you want to get a debugging prompt while browsing on your local
development server (localhost:3000) you need to run your Rails web server via Thin, because
Puma/Unicorn is not compatible with Pry.

```sh
gdk thin
```

Your Pry prompts will appear in the window that runs `gdk thin`. To go
back to using Puma/Unicorn, terminate `gdk thin` by pressing Ctrl-C
and run `gdk start`.

**Note**: It's not possible to submit commits from the web without at least two `puma/unicorn` server threads running.  Which means when running `thin` for debugging, actions such as creating a file from the web will time out. See [Use GitLab with only 1 Unicorn worker?](https://gitlab.com/gitlab-org/gitlab/issues/14546)
