# Using Prometheus with GDK

Testing the Prometheus integration with the GitLab Development Kit requires some
additional components. This is because the Prometheus integration requires a
CI/CD deploy on Kubernetes.

Because of this, you will need to either run a local Kubernetes cluster or use
a service like the Google Container Engine (GKE).

Setting it up locally with [Minikube](https://github.com/kubernetes/minikube)
is often easier, as you do not have to worry about Runners in GKE requiring
network access to your local GDK instance.

## Instructions for Minikube

The following steps will help you set up Mnikube locally.

### Install kubectl if you do not have it

Kubectl is required for Minikube to function. You can also use `homebrew` to install it using `brew install kubernetes-cli`.

1. First, download it:

    ```
    ## For macOS
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl

    ## For Linux
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    ```

1. Then, add it to your path:

    ```
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/
    ```

### Install Minikube

For macOS with homebrew, run `brew cask install minikube`.

1. First, download it:

    ```
    ## For macOS
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64

    ## For Linux
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    ```

1. Then, add it to your path:

    ```
    chmod +x ./minikube
    sudo mv ./minikube /usr/local/bin/
    ```

## Install a virtualization driver


Minikube requires virtualization. Install the appropriate driver for your operation system: [MacOS](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#hyperkit-driver) or [Linux](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver).

### Start Minikube

**Note:** If you are using a network filter such as [LittleSnitch](https://www.obdev.at/products/littlesnitch/index.html) you may need to disable it or permit `minikube`,
as minikube needs to download multiple ISO's to operate correctly.

The following command will start minikube, running the first few containers
with Kubernetes components.

**Compatibility Note:** We are not yet supporting Kubernetes 1.16, please use 1.15 the following until https://gitlab.com/gitlab-org/gitlab/issues/32721 is resolved.

For MacOS:

```
minikube start --vm-driver hyperkit --disk-size=20g --kubernetes-version=v1.15.4
```

For Linux:

```
minikube start --vm-driver kvm2 --disk-size=20g --kubernetes-version=v1.15.4
```

### Open the Kubernetes Dashboard

Once Minikube starts, open the Kubernetes dashboard to ensure things are working
You can use this for future troubleshooting.

```
minikube dashboard
```

## Configure GDK to listen to more than localhost.

From the GDK root directory, create a host file to configure GDK to listen for
more than just localhost. This will allow the Runner to connect to your GDK instance:

```
echo 0.0.0.0 > host
```

## Edit GitLab's `gitlab.yml`

We need to configure GDK to inform it of the real IP address of your computer.
This is because GDK returns this information to the Runner, and if it is wrong,
pipelines will fail.

1. Get your local IP address by running `ifconfig` or opening up Network Settings
    if on macOS. On Linux you can also use `ip addr show`.
1. Open `gitlab/config/gitlab.yml` and change the `host: localhost` line to
    reflect the IP of the previous step.
1. Save the file and restart GDK to apply this change.

You should now be able to access GitLab by the external URL
(e.g., `http://192.168.1.1` not `localhost`), otherwise it may not work correctly.

## Create a Project

Now that we have GDK running, we need to go and create a project with CI/CD
set up. The easiest way to do this, is to simply import from an existing project
with a simplified `gitlab-ci.yml`.

Import `https://gitlab.com/joshlambert/autodevops-deploy.git` as a public project, to use a very simple
CI/CD pipeline with no requirements, based on AutoDevOps. It contains just the `deploy` stages and uses a static image, since the GDK does not contain a registry.

## Allow requests to the local network

We have CSRF protection in place on the cluster url, so if we try to connect minikube now, we'll get
a `Requests to the local network are not allowed` error. The below steps will disable this protection
for use with minikube.

1. As root user, navigate to **Admin Area** (the little wrench in the top nav) > **Settings** > **Network**.
1. Expand the **Outbound requests** section, check the box to *Allow requests to the local network from hooks and services*, and save your changes.

## Connect your cluster

1. In a terminal, run `minikube ip` to get the API endpoint of your cluster.

1. Next go back to your Kubernetes cluster dashboard. If it is not open, you can open one by running `minikube dashboard`.

1. At bottom of the page you will find a list of secrets, with one named `default`. Click on it to view it, you will need these values later.

1. In your GitLab instance, go to Operations -> Kubernetes, and add a cluster. Select the option to add an existing cluster.

1. Enter any value for the `Kubernetes cluster name`.

1. For `API URL`, enter `https://<MINIKUBE_IP>:8443` using the value from step 1.

1. For `CA Certificate`, paste in the value from your Kubernetes secret.

1. Similarly for `Token`, paste the value from the Kubernetes secret.

1. Save your changes.

## Disable RBAC

AutoDevOps and Kubernetes app deployments do not yet support RBAC. To disable RBAC in your cluster, run the following command:

```
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
```

## Deploy Helm Tiller, Prometheus, and GitLab Runner

Back in the GDK on the cluster screen, you should now be able to deploy Helm Tiller. Once complete, also deploy a Runner and Prometheus.

If you get an error about an API token not yet being created, wait a minute or two and try again.

If installing Helm Tiller fails with 'Kubernetes error', you may have an existing config. To remove it:

```
kubectl delete configmap values-content-configuration-helm -n gitlab-managed-apps
```

## Run a Pipeline to deploy to an Environment

Now that we have a Runner configured, we need to kick off a Pipeline. This is
because the Prometheus integration only looks for environments which GitLab
knows about and have a successful deploy. To do this, go into Pipelines and run
a new Pipeline off `master`.

You can validate the deploy worked by looking at the Kubernetes dashboard, or
accessing the URL.

To retrieve the URL:

```
minikube service production
```

## View Performance metrics

Go to **Operations ➔ Environments** then click on an Environment. You should see
a new button appearing that looks like a chart. Click on it to view the metrics.

It may take 30-60 seconds for the Prometheus server to get a few sets of data points.

## Configuring multiple Minikube instances

Use the `--profile` or `-p` flag to define the minikube machine name. This allows multiple instances to run simultaneously. For instance, running a minikube instance for working in GitLab CE and GitLab EE at the same time can be accomplished by using all of the same commands outlined above with the additional `--profile` flag added:

For macOS:

```
minikube start --vm-driver hyperkit --disk-size=20g --profile ce-instance
minikube start --vm-driver hyperkit --disk-size=20g --profile ee-instance
```

To get the CE instance IP:

```
minikube ip --profile ce-instance
```

To look at the EE instance dashboard:

```
minikube dashboard --profile ee-instance
```

Electing to use a specified machine name will mean appending the `--profile` flag and name to each minikube command you would like to execute. Without the flag, minikube will assume you mean the default instance named `minikube`. All machines are stored by default in `~/.minikube/machines`.
