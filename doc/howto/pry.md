# Debugging with Pry

[Pry](https://pryrepl.org/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop in the magic word `binding.pry` into your code.

When running tests Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec` etc.).

If you want to get a debugging prompt while browsing on your local
development server (localhost:3000), you need to run your Rails web server via Thin
because Puma/Unicorn is not compatible with Pry. Start by kicking off the normal GDK processes via `gdk start`. Then open a new terminal session and run:

```shell
gdk thin
```

This will kill the Puma/Unicorn server and start a Thin server in its place. Once
the `binding.pry` breakpoint has been reached, Pry prompts will appear in the window
that runs `gdk thin`.

When you have finished debugging, remove the `binding.pry` breakpoint and go
back to using Puma/Unicorn. Terminate `gdk thin` by pressing Ctrl-C
and run `gdk start`.

**Note**: It's not possible to submit commits from the web without at least two `puma/unicorn` server threads running. Which means when running `thin` for debugging, actions such as creating a file from the web will time out. See [Use GitLab with only 1 Unicorn worker?](https://gitlab.com/gitlab-org/gitlab/issues/14546)
