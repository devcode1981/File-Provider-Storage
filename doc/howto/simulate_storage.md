# Simulate slow or broken repository storage

## Simulating Broken Storage Devices

To test how GitLab behaves when the underlying storage system is not working
you can simply change your local GitLab instance to use an empty directory for
the repositories. To do so edit your `gdk.yml` configuration file so that the
`git_repositories` option points to an empty directory and run `gdk reconfigure`.

## Simulating Slow Filesystems

To simulate a slow filesystem you can use the script `bin/mount-flow-fs`. This
script can be used to mount a local directory via SSHFS and slow down access to
the files in this directory. For more information see
[mount-slow-fs](#mount-slow-fs).

## mount-slow-fs

This script can be used to mount a source directory at a given mount point via
SSHFS and slow down network traffic as a way of replicating a slow NFS. Usage of
this script is as following:

    bin/mount-slow-fs path/to/actual/repositories /path/to/mountpoint

As an example, we'll use the following directories:

* Source directory: ~/Projects/repositories
* Mountpoint: /mnt/repositories

First create the mountpoint and set the correct permissions:

    sudo mkdir /mnt/repositories
    sudo chown $USER /mnt/repositories

Now we can run the script:

    bin/mount-slow-fs ~/Projects/repositories /mnt/repositories

Terminating the script (using ^C) will automatically unmount the repositories
and remove the created traffic shaping rules.
