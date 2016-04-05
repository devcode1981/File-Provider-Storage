gitlab_openldap_root = $(shell pwd)

default: slapd.d/bootstrap contents alt_contents

contents: slapd.d/schema slapd.d/example-com slapd.d/large-db
alt_contents: slapd.d/schema slapd.d/alt-example-com

slapd.d:
	mkdir slapd.d
	chmod 700 slapd.d

slapd.d/bootstrap: sbin/slapadd slapd.d
	sbin/slapadd -n 0 -F slapd.d < bootstrap.ldif
	touch $@

slapd.d/schema: sbin/slapadd
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/core.ldif
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/cosine.ldif
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/inetorgperson.ldif
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/nis.ldif
	touch $@

slapd.d/example-com: sbin/slapadd
	sbin/slapadd -b 'dc=example,dc=com' -F slapd.d < frontend.example.com.ldif
	touch $@

slapd.d/alt-example-com: sbin/slapadd
	sbin/slapadd -b 'dc=example-alt,dc=com' -F slapd.d < frontend.alt.example.com.ldif
	touch $@

slapd.d/large-db:	sbin/slapadd
	./large-db-ldif 10000 | sbin/slapadd -b 'dc=example,dc=com' -F slapd.d
	touch $@

clean:
	rm -rf slapd.d

disable_bind_anon:
	bin/ldapmodify -H ldap://127.0.0.1:3890/ -D "cn=admin,cn=config" -w password -f disable_bind_anon.ldif

openldap-2.4.40:
	curl -O ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.40.tgz
	tar zxf openldap-2.4.40.tgz

sbin/slapadd: openldap-2.4.40
	cd openldap-2.4.40 && ./configure --prefix=${gitlab_openldap_root} --enable-bdb=no --enable-hdb=no
	cd openldap-2.4.40 && make -j 2 install
