# Set up an OpenLDAP server for GitLab development

This is an attempt to set up an OpenLDAP server for GitLab development.

## Getting it running

```bash
make # compile openldap and bootstrap an LDAP server to run out of slapd.d
```

Then run the daemon:

```bash
./run-slapd # stays attached in the current terminal
```

## Repopulate the database
```
make clean default
```

## Configuring gitlab

In `gitlab.yml` under `production:` and `ldap:`, change the following keys to the below values ([defaults: `gitlab/config/gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example#L550-769):

```yaml
  enabled: true
  servers:
    main:
      # ...
      host: 127.0.0.1
      port: 3890  # on macOS: 3891
      uid: 'uid'
      # ...
      base: 'dc=example,dc=com'
      group_base: 'ou=groups,dc=example,dc=com'  # Insert this
```

alternative database (just using a different base)

```yaml
ldap:
  enabled: true
  servers:
    alt:
      label: LDAP-alt
      host: 127.0.0.1
      port: 3891  # on macOS: 3892
      uid: 'uid'
      encryption: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example-alt,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example-alt,dc=com'
      admin_group: ''
```

### Optional: disable anonymous binding

The above config doesn't use a bind user, to keeps it as simple as possible.
If you want to disable anonymous binding and require authentication run:

```bash
make disable_bind_anon
```

and update `gitlab.yml` also with the following credentials:

```yaml
ldap:
  enabled: true
  servers:
    main:
      # ...
      bind_dn: 'cn=admin,dc=example,dc=com'
      password: 'password'
      #...
```

# TODO

- integrate into the development kit
