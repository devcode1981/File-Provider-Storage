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

In `gitlab.yml` do the following;

```yaml
ldap:
  enabled: true
  servers:
    main:
      label: LDAP
      host: 127.0.0.1
      port: 3890
      uid: 'uid'
      method: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example,dc=com'
      admin_group: ''
```

alternative database (just using a different base)

```yaml
ldap:
  enabled: true
  servers:
    alt:
      label: LDAP-alt
      host: 127.0.0.1
      port: 3891
      uid: 'uid'
      method: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example-alt,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example-alt,dc=com'
      admin_group: ''
```

*Note:* We don't use a bind user for this setup, keeping it as simple as possible, but if you want to disable anonymous binding and require authentication run:

```bash
make disable_bind_anon
```

change your gitlab.yml with the following credentials:

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
## macOS Setup

On macOS run the daemon with the alt script:

```bash
./run-slapd-alt
```

and use port `3891` in `gitlab.yml` for the LDAP server.

# TODO

- integrate into the development kit
- figure out how to detect the location of `slapd`; on macOS there is `/usr/libexec/slapd`.
