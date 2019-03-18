# Google Oauth2 (GKE Cluster Integration, OAuth2 Login, etc)

## GCP Setup

1. Visit "API & Services" https://console.cloud.google.com/apis/credentials
1. Click "Create credentials" > "Oauth Client ID"
1. Choose "Web application" as Application type
1. Fill the form with application name
1. Fill in following URLs in "Authorized redirect URIs"
 - http://localhost:3000/users/auth/google_oauth2/callback # For Oauth2 Login
 - http://localhost:3000/-/google_api/auth/callback  # For GKE Cluster Integration
1. Click "Create" button
1. Visit the entry. Copy Client ID and Client secret to 'gitlab.yml' as described below

## GDK Setup

1. Configure gitlab/config/gitlab.yml

    ```yml
    development:
    <<: *base
    omniauth:
        providers:
        - { name: 'google_oauth2',
            app_id: 'Here is your Client ID',
            app_secret: 'Here is your Client secret',
            args: { access_type: 'offline', approval_prompt: '' } }

    ```

1. Run GDK
