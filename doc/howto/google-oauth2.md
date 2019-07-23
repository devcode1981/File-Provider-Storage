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
1. Visit the entry. Copy Client ID and Client secret as described below

## GDK Setup

From the GDK root directory, run:

```bash
echo "<google-client-id>" > google_oauth_client_id
echo "<google-client-secret>" > google_oauth_client_secret
gdk reconfigure
```
