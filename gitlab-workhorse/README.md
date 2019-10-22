# GitLab-Workhorse in GitLab Development Kit

To recompile and restart workhorse in GDK, run:

```
make gitlab-workhorse-setup && gdk restart gitlab-workhorse
```

In GDK, gitlab-workhorse is installed inside its own GOPATH rooted
here.

The gitlab-workhorse repository is cloned into:

```
src/gitlab.com/gitlab-org/gitlab-workhorse
```

You can use the following shortcut to `cd` into that directory:

```
. cd.sh
```

## Cleaning up an old gitlab-workhorse checkout

If you installed GDK before we started using a GOPATH for
gitlab-workhorse you now have a bit of a mess in this directory. You
can clean up as follows. Start in the GitLab Development Kit root.

```
# in GDK root!!
mv gitlab-workhorse gitlab-workhorse.old.$(date +%s)
git checkout -- gitlab-workhorse
rm Procfile
make
```
