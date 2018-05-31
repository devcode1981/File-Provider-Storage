# SAML

You can run a test SAML identity provider using the [kristophjunge/test-saml-idp](https://hub.docker.com/r/kristophjunge/test-saml-idp/)
docker image, both to test instance-wide SAML and the multi-tenant Group SAML used on GitLab.com

## Group SAML

This requires [HTTPS](https.md) to be set up locally and the identity provider to be configured using your group's callback URL and entity ID.

For example, an identity provider for the "zebra" group can be ran using the following:

```shell
docker run --name=gitlab_saml_idp -p 8080:8080 -p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=https://localhost:3443/groups/zebra \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=https://localhost:3443/groups/zebra/-/saml/callback \
-d kristophjunge/test-saml-idp
```

From GitLab this would then be configured using:

- **SSO URL:** https://localhost:8443/simplesaml/saml2/idp/SSOService.php
- **Certificate fingerprint:** 119b9e027959cdb7c662cfd075d9e2ef384e445f

![Group SAML Settings for Docker](img/group-saml-settings-for-docker.png)

## Credentials

The following users are described in the [docker image documenation](https://hub.docker.com/r/kristophjunge/test-saml-idp/#usage):

| Username | Password |
| -------- | -------- |
| user1 | user1pass |
| user2 | user2pass |
