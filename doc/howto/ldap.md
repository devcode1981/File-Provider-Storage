# Set up an OpenLDAP server for GitLab development

You can run an OpenLDAP daemon inside GDK if you want to work on GitLab LDAP integration.

## Getting it running

```shell
cd <gdk-directory>/gitlab-openldap
make # compile openldap and bootstrap an LDAP server to run out of slapd.d
```

We can also simulate a large instance with many users and groups:

```shell
make large
```

Then run the daemon:

```shell
./run-slapd # stays attached in the current terminal
```

## Configuring GitLab

In `gitlab.yml` under `production:` and `ldap:`, change the following keys to the values
given below (see [defaults](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example#L550-769)):

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

In GitLab EE, an alternative database can optionally be added as follows:

```yaml
    main:
      # ...
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

The following users are added to the LDAP server:

| uid      | Password | DN                                          | Last     |
| -------- | -------- | -------                                     | ----     |
| john     | password | `uid=john,ou=people,dc=example,dc=com`      |          |
| john0    | password | `uid=john0,ou=people,dc=example,dc=com`     | john9999 |
| mary     | password | `uid=mary,ou=people,dc=example,dc=com`      |          |
| mary0    | password | `uid=mary0,ou=people,dc=example,dc=com`     | mary9999 |
| bob      | password | `uid=bob,ou=people,dc=example-alt,dc=com`   |          |
| alice    | password | `uid=alice,ou=people,dc=example-alt,dc=com` |          |

For testing of GitLab Enterprise Edition the following groups are created.

| cn            | DN                                              | Members | Last          |
| -------       | --------                                        | ------- | ----          |
| group1        | `cn=group1,ou=groups,dc=example,dc=com`         | 2       |               |
| group2        | `cn=group2,ou=groups,dc=example,dc=com`         | 1       |               |
| group-10-0    | `cn=group-10-0,ou=groups,dc=example,dc=com`     | 10      | group-10-1000 |
| group-100-0   | `cn=group-100-0,ou=groups,dc=example,dc=com`    | 100     | group-100-100 |
| group-1000-0  | `cn=group-1000-0,ou=groups,dc=example,dc=com`   | 1,000   | group-1000-10 |
| group-10000-0 | `cn=group-10000-0,ou=groups,dc=example,dc=com`  | 10,000  | group-10000-1 |
| group-a       | `cn=group-a,ou=groups,dc=example-alt,dc=com`    | 2       |               |
| group-b       | `cn=group-b,ou=groups,dc=example-alt,dc=com`    | 1       |               |

## Repopulate the database

```shell
cd <gdk-directory>/gitlab-openldap
make clean default
```

### Optional: disable anonymous binding

The above config does not use a bind user, to keep it as simple as possible.
If you want to disable anonymous binding and require authentication:

1. Run the following command:

   ```shell
   make disable_bind_anon
   ```

1. Update `gitlab.yml` also with the following:

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

## TODO

- integrate into the development kit
