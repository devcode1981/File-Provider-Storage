# LDAP

You can run an OpenLDAP daemon inside GDK if you want to work on GitLab LDAP integration.

To run the OpenLDAP installation included in the GitLab development kit do the following:

```shell
cd gitlab-openldap
make # will setup the databases
```

Then edit `gdk.yml` (in the GDK top level directory) and add:

```yaml
openldap:
  enabled: true
```

In the `gitlab` repository edit `config/gitlab.yml`:

```yaml
ldap:
  enabled: true
  servers:
    main:
      label: LDAP
      host: 127.0.0.1
      port: 3890
      uid: 'uid'
      encryption: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example,dc=com'
      admin_group: ''
    # Alternative server, multiple LDAP servers only work with GitLab-EE
    # alt:
    #   label: LDAP-alt
    #   host: 127.0.0.1
    #   port: 3890
    #   uid: 'uid'
    #   encryption: 'plain' # "tls" or "ssl" or "plain"
    #   base: 'dc=example-alt,dc=com'
    #   user_filter: ''
    #   group_base: 'ou=groups,dc=example-alt,dc=com'
    #   admin_group: ''
```

The second database is optional, and will only work with GitLab EE.

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
