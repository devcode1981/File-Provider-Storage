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

Kubectl is required for Minikube to function.

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

1. First, download it:

    ```
    ## For macOS
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.17.1/minikube-darwin-amd64

    ## For Linux
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.17.1/minikube-linux-amd64
    ```

1. Then, add it to your path:

    ```
    chmod +x ./minikube
    sudo mv ./minikube /usr/local/bin/
    ```

## Set the Minikube default VM driver

We need to install a VM in order to be able to use Minikube. Xhyve is one method,
unless you have VMware Fusion or Virtual box installed.

See the [Minikube drivers documentation](https://github.com/kubernetes/minikube/blob/master/DRIVERS.md)

Once you have the VM provider of your choice installed, set it as the default
VM driver:

```
minikube config set vm-driver xhyve
```

Replace `xhyve` with `virtuabox`, `vmware` or `kvm` depending on what VM provider
you chose to use.

### Start Minikube

The following command will start minikube, running the first few containers
with Kubernetes components:

```
minikube start
```

### Open the Kubernetes Dashboard

Once Minikube starts, open the Kubernetes dashboard to ensure things are working
You can use this for future troubleshooting.

```
minikube dashboard
```

## Launch Prometheus

Next, we tell Kubernetes to launch an instance of Prometheus, and we provide
the configuration in the `ConfigMap`.

```
kubectl apply -f support/prometheus/prometheus-configmap.yml
kubectl apply -f support/prometheus/prometheus-svc.yml
kubectl apply -f support/prometheus/prometheus-deployment.yml
```

## Get Prometheus Service URL

The following command will display the URL to access the newly started Prometheus
server. Browse to it to ensure it is operational:

```
minikube service --url prometheus
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

Import https://gitlab.com/joshlambert/hello-world.git, to use a very simple
CI/CD pipeline with no requirements (it just spins up a hello-world container).

## Edit the Runner's configMap yaml file

This file configures the Runner to talk to GDK, and we need to edit two sections
of this file.

1. Open it with your editor:

    ```
    support/prometheus/gitlab-runner-docker-configmap.yml
    ```

1. Replace the existing IP with your local IP address that you found when you
   configured `gitlab.yml`.
1. Replace the registration token with the Runner's token of your project. Find
   it under **Project ➔ Settings ➔ CI/CD Pipelines ➔ Runner token**.

    >**Note:**
    If your project's token contains uppercase characters, it will fail
    due to a bug in the Runner. You can manually set the token further down
    the CI/CD settings screen. Set it to all lowercase letters and numbers.

1. Save your changes.

## Deploy GitLab Runner

Use the following yaml files to deploy GitLab Runner:

```
kubectl apply -f support/prometheus/gitlab-runner-docker-configmap.yml
kubectl apply -f support/prometheus/gitlab-runner-docker-deployment.yml
```

You can view the Pod logs to confirm it registered successfully.

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

If the deploy failed, you may need to edit the project's runner token to not
include capital letters. (See Note in the step above.)

## Configure Prometheus Service Integration

Finally, we are ready to configure the Prometheus integration.

1. Go to **Project ➔ Settings ➔ Integrations ➔ Prometheus**.
1. Enter the [Prometheus URL](#get-prometheus-service-url) and click Active.
1. Save and test.

## View Performance metrics

Go to **Pipelines ➔ Environments** then click on an Environment. You should see
a new button appearing that looks like a chart. Click on it to view the metrics.

It may take 30-60 seconds for the Prometheus server to get a few sets of data points.
