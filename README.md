# Restarter Job

This project allows users to restart any deployments in Openshift Platform.

## Getting started

The restarter Job has a few requirements before it can be executed successfully:

- Non-default Kubernetes ServiceAccount
- Kubernetes Roles and RoleBindings

These requirements are already provided in the `openshift` directory. These must be deployed to Openshift prior to the Job.

Once the conditions are met, it will be possible to run the Job. Below are the arguments for the job. `NAMESPACE` is already set, so only `DEPLOYMENT` needs to be provided.

|Parameter  |Default|Description                |
|-----------|-------|---------------------------|
|NAMESPACE  |""     |Target deployment namespace|
|DEPLOYMENT |""     |Target deployment name     |

## Testing

To test the image, you set up a local `minikube` cluster and run the Job against a deployment stub.

Create cluster:

```bash
$ make minikube
/usr/local/bin/docker
/opt/homebrew/bin/minikube
/opt/homebrew/bin/kubectl
😄  minikube v1.32.0 on Darwin 14.1 (arm64)
✨  Using the docker driver based on user configuration
📌  Using Docker Desktop driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4000MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Run test:

```bash
$ make test
service/stub created
deployment.apps/stub created
Waiting for deployment "stub" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "stub" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "stub" rollout to finish: 2 of 3 updated replicas are available...
deployment "stub" successfully rolled out
serviceaccount/restarter created
job.batch/cbit-restarter-job created
role.rbac.authorization.k8s.io/restarter created
rolebinding.rbac.authorization.k8s.io/restarter created
pod/cbit-restarter-job-rhbhm condition met
2023-11-10T13:06:10Z INF src/cmd/restarter/main.go:84 > Waiting for deployment "stub" rollout to finish...
2023-11-10T13:06:13Z INF src/cmd/restarter/main.go:84 > Waiting for deployment "stub" rollout to finish...
2023-11-10T13:06:15Z INF src/cmd/restarter/main.go:84 > Waiting for deployment "stub" rollout to finish...
2023-11-10T13:06:17Z INF src/cmd/restarter/main.go:84 > Waiting for deployment "stub" rollout to finish...
2023-11-10T13:06:19Z INF src/cmd/restarter/main.go:80 > deployment "stub" successfully rolled out
```

## Dockerhub

Build and upload all images to JFrog Artifactory:

```bash
make artifact USER=DOCKERHUB_USER SECRET=DOCKERHUB_SECRET
```

## Help

```bash
Usage:
  make <target>
  help             Displays help

Development
  fmt              Formats the source code
  vet              Validates the source code
  build            Builds the image
  run              Builds and runs the image
  artifact         Pushes the images to JFrog Artifactory
  clear            Removes the images
  changelog        Generate changelog

Test
  minikube         Creates a minikube cluster
  rm_minikube      Removes the minikube cluster
  test             Tests the restarter job
```
