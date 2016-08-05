# SSH

If you want to work on GitLab's SSH integration then uncomment the
'sshd:' line in your Procfile. Next time you start `run` or `run app`
you will get an unprivileged SSH daemon process running on
localhost:2222, integrated with gitlab-shell.

To change the host/port you need to edit openssh/sshd_config and
gitlab/config/gitlab.yml. If you are not working on GitLab SSH
integration we recommend that you leave the 'sshd:' line in the
Procfile commented out.
