# Web IDE Terminal

[Web IDE terminal](https://docs.gitlab.com/ee/user/project/web_ide/index.html#interactive-web-terminals-for-the-web-ide-ultimate-only)
can be tested using the GDK. Currently, this requires an Ultimate license, but this
won't be needed once [this feature is moved to Core](https://gitlab.com/gitlab-org/gitlab/-/issues/211685).

## Pre-requisites

To run Web IDE terminals on GDK, the following are required:

- [GDK up and running](doc/set-up-gdk.md).
- An [Ultimate license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee).
  Note that the license key generator is only available for GitLab team members.
- CI/CD enabled on a local project. To check this:
  1. Navigate to the project's **Settings > General**.
  1. Expand **Visibility, project features, permissions**.
  1. Confirm **Pipelines** is enabled.
- [GitLab Runner](runner.md) installed.
- [Minikube](https://docs.gitlab.com/charts/development/minikube/#getting-started-with-minikube)
  installed and started. Start Minikube with a driver of your choice (VirtualBox in this case):

  ```shell
  minikube start --driver=virtualbox
  ```

## GDK configuration

To configure GDK for Web IDE terminals:

1. Ensure GDK is stopped with `gdk stop`.
1. Run `ifconfig` to get your local IP address.
1. Set the host parameter for GDK to be your local IP address:

   ```shell
   cd <GDK root>
   echo "<local IP address>" > host
   ```

1. Reconfigure and restart GDK:

   ```shell
   gdk reconfigure
   gdk restart
   ```

1. (Optional) Check you can access the app at `http://<local IP address>:3000`.

## Minikube setup

1. Add the following to a [`role.yml`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
   file:

   ```yml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     namespace: default
     name: gitlab-ci
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["pods", "pods/exec", "secrets"]
     verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
   ```

1. Add the following to a [`role-binding.yml`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
   file:

   ```yml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: gitlab-ci
     namespace: default
   subjects:
   - kind: ServiceAccount
     name: default # Name is case sensitive
     namespace: default
   roleRef:
     kind: Role #this must be Role or ClusterRole
     name: gitlab-ci # this must match tile name of the Role or ClusterRole you wish to bind to
     apiGroup: rbac.authorization.k8s.io
   ```

1. Apply the configurations:

   ```shell
   kubectl apply -f role-binding.yml
   kubectl apply -f role.yml
   ```

1. Restart Minikube:

   ```shell
   minikube stop
   minikube start --driver=virtualbox
   ```

## GitLab Runner setup

The following is required to configure GitLab Runner for Web IDE terminals.

### Register and start the runner

1. Open the local GitLab app and navigate to your test project.
1. Go to **Settings > CI/CD**
1. Expand **Runners** and refer to the information at **Set up a specific Runner manually**,
   making note of the URL and token.
1. [Register](https://docs.gitlab.com/runner/register/) the Runner:

   ```shell
   gitlab-runner register
   ```

   - Follow the prompt to provide the URL, token, and description for the Runner.
   - Tags are optional.
   - Select `kubernetes` as the executor.

1. (Optional) Go to **Settings > CI/CD** to check the Runner was registered successfully.
1. Start the Runner:

   ```shell
   gitlab-runner run
   ```

1. Go to **Settings > CI/CD** again to check the Runner is shown as online (next to a green circle).

### Update Runner configuration

1. Get Bearer token from Kubernetes:

   ```shell
   kubectl get secrets -ojsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}" | base64 -D
   ```

1. Add the token to the [`[[runners]]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
   section of `~/.gitlab-runner/config.toml` as follows:

   ```yml
   [[runners]]
     [runners.kubernetes]
       host = ""
       bearer_token = "token_from_step_one"
   ```

1. Add your IP address as the `listen_address` to the [`[session_server]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section)
   section using `host:port` format:

   ```yml
   [session_server]
     session_timeout = 1800
     listen_address = "<local IP address>:8080"
   ```

1. Restart the Runner:

   ```shell
   gitlab-runner restart
   ```

## Starting the Web IDE terminal

1. Go to the test project and open the Web IDE.
1. Add the file `.gitlab/.gitlab-webide.yml` to the repository's root.

   ```yml
   terminal:
     image: node:10-alpine
     before_script:
       - apt-get update
     script: sleep 60
     variables:
       RAILS_ENV: "test"
       NODE_ENV: "test"
   ```

   Check the [Web IDE configuration file](https://docs.gitlab.com/ee/user/project/web_ide/#web-ide-configuration-file)
   section for more information about this file's syntax.
1. From the menu on the left, click on the Terminal icon.
1. Start the Web IDE terminal.

## Troubleshooting

The following are possible problems using Web IDE terminal with possible solutions:

- If you experience a seemingly never ending spinner, it may be that your
  concurrency setting is set to 1 and you have a regular pipeline job
  running.

  This could be solved by canceling that running job, so that the
  terminal one can start.

- In case of a `connection failure` (due to `apt-get` command not being
  found), you can try changing the `image` in `.gitlab/.gitlab-webide.yml`
  to be `image: alpine:3.5`.

  This is a bit inconsistent as you could later try to change it back to
  `image: node:10-alpine` and still get it to work, but it may help getting
  past the initial error.

- If you're still having trouble getting the terminal up and running in
  Web IDE, it maybe worth trying the "regular" [debug terminal for
  pipeline jobs](https://docs.gitlab.com/ee/ci/interactive_web_terminal/#debugging-a-running-job),
  as it requires less configuration.

  That is, the GitLab instance doesn't need to ping out to the Runner like it
  does for the IDE terminal). In this case, your `.gitlab-ci.yml` file should look like
  this:

  ```yml
  job:
    image: alpine:latest
    stage: test
    script:
    - sleep 300
  ```

  If that fails, you can switch to using a Docker Runner, which is far
  simpler to set up. If that works, it points to it being a
  Kubernetes setup issue.
