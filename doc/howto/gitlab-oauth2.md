# GitLab.com OAuth2 authentication

Import projects from GitLab.com and login to your GitLab instance with your GitLab.com account.

## GitLab.com Setup

To enable the GitLab.com OmniAuth provider, you must register your GDK instance with
your GitLab.com account.
GitLab.com will generate an application ID and secret key for you to use.

1. Sign in to GitLab.com.
1. On the upper right corner, click on your avatar and go to your **Settings**.
1. Select **Applications** in the left menu.
1. Provide the required details for **Add new application**:

   - Name: This can be anything. Consider something descriptive such as "Local GitLab.com OAuth".
   - Redirect URI: Make sure this matches what you have set for your localhost (for example,
     [`gdk.test:3000`](../index.md#set-up-gdktest-hostname)) or qa-tunnel:

     ```plaintext
     http://gdk.test:3000/import/gitlab/callback
     http://gdk.test:3000/users/auth/gitlab/callback
     ```

     The first link is required for the importer and second for the authorization.

1. Select **Save application**.
1. You should now see an **Application ID** and **Secret**. Keep this page open as you continue
   configuration.

## GDK Setup

1. Within GDK, open `gitlab/config/gitlab.yml`.
1. Look for the following:

    ```yaml
    development:
    <<: *base
        omniauth:
            providers:
    ```

1. Under `providers`, indent and add:

   ```yaml
   - { name: 'gitlab',
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { scope: 'api' } }
   ```

   Update `YOUR_APP_ID` and `YOUR_APP_SECRET` with values that were generated in the
   previous step.

1. Run `gdk restart`.

You should now be able to import projects from GitLab.com, as well as sign in to your
instance with a GitLab.com account.

*NOTE:* Running `gdk reconfigure` will remove your provider and you will need to re-add it.
