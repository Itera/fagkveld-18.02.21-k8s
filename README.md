# Fagkveld 18.02.21 - MAD Platform and Kubernetes

## Contents

* [1. Description](#1-description)
* [2. Setup](#2-setup)
* [3. Labs](#3-labs)
  * [3.1 Lab 01 - premade image](#31-lab-01---premade-image)
  * [3.2 Lab 02 - custom application](#32-lab-02---custom-application)
  * [3.3 Lab 03 - Kustomize](#33-lab-03---kustomize)

## 1. Description

Hands on event where we will learn how to deploy basic workloads to Kubernetes using our cluster in the MAD Platform.

We will
1. Create an application locally
2. Build it using Docker
3. Push the docker image to the MAD Platform container registry
4. Build basic Kubernetes manifests
5. Deploy to Kubernetes

Prereqs:
* Docker CLI
  * https://docs.docker.com/get-docker/

Nice to have tools: 
* GUI - https://k8slens.dev/
* TUI - https://github.com/derailed/k9s

Handy resources:
* kubectl cheatsheet - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
* kubectl reference - https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands

## 2. Setup

This will setup CLI and access to Azure and Kubernetes, and let you create a Kubernetes namespace to experiment in.

Options:
* Use powershell directly, with az, docker, kubectl, kustomize preinstalled
* Use bash directly, with az, docker, kubectl, kustomize preinstalled
* Build or pull k8sdev:latest container which has all the tools preinstalled

A `secrets.ps1` file and a `secrets.sh` file will be posted when we start the fagkveld

```
> cat secrets.ps1
$SP_ID="<azure-service-principal-id>"
$SP_PW="<azure-service-principal-password>"
$NS="fagkveld-<insert-your-name-here>" # i.e. "fagkveld-martinothamar"
$REG="<azure-registry>"
$K8S="<aks-cluster-name>"
$RG="<resource-group-name>"
$TENANT="<azure-tenant-id>"
$SUBSCRIPTION="<subscription>"

# If using powershell
> . .\secrets.ps1

# If using bash (mac or linux)
> source secrets.sh
```


```sh
# First we need to build and enter the dev container.
# The dev container is the 'Dockerfile' in the root folder,
# which is meant to install all required tooling for these labs
./build-dev.ps1
# or
./build-dev.sh
# or
docker pull martinothamar/k8sdev:latest
docker tag martinothamar/k8sdev:latest k8sdev:latest

# Then we can enter into the container.
./run-dev.ps1
# or
./run-dev.sh

# Now we have entered the Ubuntu 20.04 based dev container with tools installed:
# az, docker, kubectl, helm, kustomize, k9s

# We can log into Azure using the service principal (SP auth is needed unless you are running Intune registrered device)
az login --service-principal -u $SP_ID -p $SP_PW --tenant $TENANT
# or if you just want to use your AAD account and your computer is registered in Intune
az login

# Set the current subscription to MAD Platform
az account set -s "$SUBSCRIPTION"
az account show

# Let Azure CLI create the Kubernetes config file used by kubectl
# It creates/updated at C:\Users\<username>\.kube\config and equivalent for other OS'
# The config file contains certificate, token and URL for the MAD Platform cluster
az aks get-credentials -n $K8S -g $RG

# Make sure we are logged into the Azure Container Registry, for pushing images later
az acr login -n $REG

# This creates the namespace. This is the shorthand way, a namespace can also be created by defining YAML manifest.
kubectl create namespace $NS
# You should now be set to follow along with the all labs
```

## 3. Labs

### 3.1 Lab 01 - premade image

In this lab we will create a simple deployment using existing docker image `stefanprodan/podinfo`

```sh
# Take a look at the manifest
# 'apply' tells Kubernetes to accept the configuration in the manifest as desired state.
# If the resource in the manifest already exist, it will be updated in the case of changes
# '-n' is for namespace, '-f' is for file
kubectl apply -n $NS -f 01/deployment.yaml

# Tip: Lens or k9s to view the resource

# 'logs' subcommand is used to view the output (stdout/stderr, so console.log/Console.WriteLine etc) of the container in the pods
# you can select all pods for a deployment, or a single pod. In this case, all pods for the deployment
# '--tail' tells the command to tail the last N lines of the output
# '-f' is for follow, the command doesn't terminate until 'ctrl/cmd+c'
kubectl logs -n $NS deployment/podinfo-deployment --tail=10 -f

# Gets pods matching label selectors
# For the various resurces such as pods, there are shorthand names also accepted: pods | pod | po, deployments | deployment | deploy
# '-l' is for a label selector. Since we have a label named 'app' with the value 'podinfo' in the deployment manifest from earlier, 
# this will output all pods with that label. These labels work for lots of different kubectl subcommands
# '-o' is for output format, there are various formats available, some of them are: name | wide | yaml | jsonpath
# See the cheatsheet under resources for more options
kubectl get pods -n $NS -l app=podinfo -o wide

# Gets the resource consumption of the pod
# i.e. 'kubectl top pods -n $NS podinfo-deployment-5b4ffd45f-nh8cq'. Example output:
# > NAME                                 CPU(cores)   MEMORY(bytes)
# > podinfo-deployment-5b4ffd45f-nh8cq   1m           15Mi
# 1m = 1 millicpu = 1/1000 CPU core
kubectl top pods -n $NS <name-here>

# Create a tunnel for TCP traffic from local port 9898 to pod port 9898
# which means any traffic we request from localhost:9898 is tunneled directly into the running container in the cluster
kubectl port-forward -n $NS --address 0.0.0.0 deployment/podinfo-deployment 9898:9898
# Now open http://localhost:9898 in a browser or run
curl http://localhost:9898/version
# 'ctrl-c' to stop

# Get a shell promt in the runnig container in the pod
# i.e. 'kubectl exec -n $NS -it podinfo-deployment-5b4ffd45f-nh8cq -- /bin/sh'
kubectl exec -n $NS -it <name-here> -- /bin/sh
# Now inside the container
ls -l
# And exit
exit

# This is the same as when we applied, except now we will delete the resource
kubectl delete -n $NS -f 01/deployment.yaml

# Should now be empty
kubectl get pods -n $NS
```

### 3.2 Lab 02 - custom application

In this lab we will package a custom app as a container image, push it to our container registry and deploy it.

```sh
# Lets setup an app
cd app/

# Choose on of the applications in this folder
cd <folder>/

# Build the application into a Docker image
docker build . -t $REG/fagkveld-test-api:$NS

# Test it locally
docker run --rm -it -p 8090:8090 -e SECRET="this is a secret" --init $REG/fagkveld-test-api:$NS
# Now open http://localhost:8090 in a browser or run
curl http://localhost:8090/hello
# 'ctrl-c' to stop

# Push the newly built image to the MAD Platform container image registry
docker push $REG/fagkveld-test-api:$NS

# Now we are done with the Docker/app-specific things.
# Wether you chose ASP.NET Core with C# or Spring Boot with Kotlin is immaterial and the process was the same. 
# The docker image (the artifact for deployment) is OCI (Open Container Initiative) compliant,
# which means that Kubernetes will understand it and be able to schedule it on a node in the cluster

# Now we can move up and deploy the image we built using a Kubernetes manifest (the configuraiton)
cd ../../
# For this part we need to update the deployment manifest here: 02/deployment.yaml
# You need to insert the 'image:' field. The value of the field should be the output of the command below
echo $REG/fagkveld-test-api:$NS

# Now that the manifest has an image for the container, we can deploy it
kubectl apply -n $NS -f 02/deployment.yaml

kubectl logs -n $NS deployment/fagkveld-test-api-deployment --tail=10 -f

# Again we can create a tunnel to our pod
kubectl port-forward -n $NS --address 0.0.0.0 deployment/fagkveld-test-api-deployment 8091:8090
# Now open http://localhost:8091/hello in a browser or run
curl http://localhost:8091/hello
# You should see the output 'word'
# 'ctrl-c' to stop

# Same as before, clean up
kubectl delete -n $NS -f 02/deployment.yaml
```

### 3.3 Lab 03 - Kustomize

In this lab we will deploy the same custom application but where Kustomize constructs the final template.

```sh
# Using Kustomize we will produce an output containing all the manifests we need
# We can substitute placeholder with variables and do merging and patching between environments (overlays) and the base
cd 03/base
# This will add an 'images' section to the base 'kustomization.yaml' config
kustomize edit set image custom-image=$REG/fagkveld-test-api:$NS
# Then make sure the namespace field is added to all manifests in the base
kustomize edit set namespace $NS
cd ../../

# Now we have to override the secret in the development environment we want to deploy
echo "SECRET=<some-secret>" >  03/overlays/development/secret.env

# Now we can build and inspect the output
kustomize build 03/overlays/development/

# And we can apply
kustomize build 03/overlays/development/ | kubectl apply -f -

# Check for no errors
kubectl logs -n $NS deployment/fagkveld-test-api-deployment --tail=10 -f

# Make sure it works
kubectl port-forward -n $NS --address 0.0.0.0 deployment/fagkveld-test-api-deployment 8091:8090

# Now cleanup
kustomize build 03/overlays/development/ | kubectl delete -f -
```

#### TODO

* oyvindne local microk8s
* finish lab 04 for Helm
