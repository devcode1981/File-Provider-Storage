# Auto DevOps - Useful Commands

This is a reference list of some useful commands one might need when contributing to Auto DevOps.

Be sure also to check our [Tips and Troubleshooting](./tips_and_troubleshooting) section.

# GKE

## `kubectl` Config

View your full `kubectl` config:

```bash
kubectl config view
```

or:

```bash
cat ~/.kube/config
```

You can also view a specific config, like getting the list of known clusters:

```bash
kubectl config get-cluster
```

or, _very important_, know to which context your kubectl is current connected to:

```bash
kubectl config current-context
```

This determines if you're communicating to your local development cluster (Minikube for instance) or your remote cluster (hosted on GKE for instance). It also determines which cluster [Helm](#helmtiller-commands) is going to be communicating to.

## Change your current context

If you'd like to change your current-context to point to a different cluster, with `gcloud`, you can:

```bash
gcloud container clusters get-credentials cluster-name-here
```

## Get Nodes, Pods, Deployments, Jobs, Secrets

You can get one information at a time:

```bash
kubectl get nodes
```

or many at once:

```bash
kubectl get nodes,pods,deployments,jobs,secrets
```

`kubectl` looks for objects in the `default` namespace. So to see our GitLab deployed objects, use this flag:

```bash
kubectl get pods -n gitlab-managed-apps
```

or:

```bash
kubectl get pods --all-namespaces
```

## Logging Pods

To see the complete log:

```bash
kubectl logs pod-name-here -n gitlab-managed-apps
```

or to see the last *n* lines use the `--tail` flag:

```bash
kubectl logs {pod-name-without-braces} --tail=20 -n gitlab-managed-apps
```

you can combine it with `watch` to keep reading the file every *n* seconds:

```bash
watch -n3 kubectl logs {pod-name-without-braces} --tail=20 -n gitlab-managed-apps
```

if you're on mac you might need to install `watch` first:

```bash
brew install watch
```

## Helm/Tiller Commands

[Helm](https://docs.helm.sh/) is the package manager for Kubernetes. When running `helm` commands on your local machine, [Helm](https://docs.helm.sh/) will then communicate remotely with [Tiller](https://docs.helm.sh/glossary/#tiller), its in-cluster component. [Tiller](https://docs.helm.sh/glossary/#tiller) interacts directly with the Kubernetes API server to install, upgrade, query, and remove Kubernetes resources. It also stores the objects that represent releases.

If you are only interested about running `helm` commands locally, you can use the `--client-only` flag:

```bash
helm version --client-only
```

To initialize [Helm](https://docs.helm.sh/) in your machine and create your `~/.helm` configuration directory, run:

```bash
helm init --client-only
```

### Talking to Tiller

In our Auto DevOps scenario, we need to consider 3 things before setting up the Helm/Tiller communication:

  1 - Make sure your `kubectl config current-context` is pointing to the correct cluster. If it isn't, then [change your current-context](#change-your-current-context)

  2 - When we install Helm/Tiller through [GitLab Auto DevOps](https://docs.gitlab.com/ee/topics/autodevops), Tiller is configured with SSL communication enabled. Therefore, Helm can only talk to it if it has the proper certificates used during the Tiller installation.

  3 - All our [GitLab Auto DevOps](https://docs.gitlab.com/ee/topics/autodevops) Kubernetes apps are installed under the `gitlab-managed-apps` namespace.

So, considering *1 - current-context* is correct, we now need to create the SSL certificate files on our local environment. Luckily, we do save those certificates on our database when we created this Helm/Tiller on our cluster. So, go ahead to your GitLab repository and run the below script on your `bundle exec rails c`:

```ruby
helm = Clusters::Applications::Helm.last; nil

File.open('/tmp/ca_cert.pem', 'w') { |f| f.write(helm.ca_cert) }; nil

client_cert = helm.issue_client_cert; nil

File.open('/tmp/key.pem', 'w') { |f| f.write(client_cert.key_string) }; nil
File.open('/tmp/cert.pem', 'w') { |f| f.write(client_cert.cert_string) }; nil
```

Now we already have proper SSL files: `/tmp/ca_cert.pem`, `/tmp/key.pem` and `/tmp/cert.pem`. So let's finnaly run Helm commands that will be executed also on our server via Tiller communication:

```bash
helm version --tls \
  --tls-ca-cert /tmp/ca_cert.pem \
  --tls-cert /tmp/cert.pem \
  --tls-key /tmp/key.pem \
  --tiller-namespace=gitlab-managed-apps
```

Note that we stopped using `--client-only`, but instead we added the tls flags:

- `--tls`
- `--tls-ca-cert /tmp/ca_cert.pem`
- `--tls-cert /tmp/cert.pem`
- `--tls-key /tmp/key.pem`

and the `--tiller-namespace=gitlab-managed-apps` flag.