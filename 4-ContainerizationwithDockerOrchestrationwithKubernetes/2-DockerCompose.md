# Deploy a multi-container group using Docker Compose 

In this tutorial, you use [Docker Compose](https://docs.docker.com/compose/) to define and run a multi-container application locally and then deploy it as a [container group](container-instances-container-groups.md) in Azure Container Instances. 

## Prerequisites

* **Git** - You must have the Git installed on your local computer, see [Install Git](https://git-scm.com/downloads).

* **Azure CLI** - You must have the Azure CLI installed on your local computer. Version 2.10.1 or later is recommended. Run `az --version` to find the version. If you need to install or upgrade, see [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

* **Docker Desktop** - You must use Docker Desktop version 2.3.0.5 or later, available for [Windows](https://desktop.docker.com/win/edge/Docker%20Desktop%20Installer.exe) or [macOS](https://desktop.docker.com/mac/edge/Docker.dmg). Or install the [Docker ACI Integration CLI for Linux](https://docs.docker.com/engine/context/aci-integration/#install-the-docker-aci-integration-cli-on-linux).

## Create Azure container registry

First, you need to log into azure:
```azurecli
az login
```

Before you create your container registry, you need a *resource group* to deploy it to. A resource group is a logical collection into which all Azure resources are deployed and managed.

Create a resource group with the [az group create][az-group-create] command. In the following example, a resource group named *myResourceGroup* is created in the *eastus* region:

```azurecli
az group create --name myResourceGroup --location eastus
```

Once you've created the resource group, create an Azure container registry with the [az acr create][az-acr-create] command. The container registry name must be unique within Azure, and contain 5-50 alphanumeric characters. Replace `<acrName>` with a unique name for your registry:

```azurecli
az acr create --resource-group myResourceGroup --name <acrName> --sku Basic
```

Here's partial output for a new Azure container registry named *mycontainerregistry082*:

```output
{
  "creationDate": "2020-07-16T21:54:47.297875+00:00",
  "id": "/subscriptions/<Subscription ID>/resourceGroups/myResourceGroup/providers/Microsoft.ContainerRegistry/registries/mycontainerregistry082",
  "location": "eastus",
  "loginServer": "mycontainerregistry082.azurecr.io",
  "name": "mycontainerregistry082",
  "provisioningState": "Succeeded",
  "resourceGroup": "myResourceGroup",
  "sku": {
    "name": "Basic",
    "tier": "Basic"
  },
  "status": null,
  "storageAccount": null,
  "tags": {},
  "type": "Microsoft.ContainerRegistry/registries"
}
```

The rest of the tutorial refers to `<acrName>` as a placeholder for the container registry name that you chose in this step.

## Log in to container registry

You must log in to your Azure Container Registry instance before pushing images to it. Use the [az acr login][az-acr-login] command to complete the operation. You must provide the unique name you chose for the container registry when you created it.

```azurecli
az acr login --name <acrName>
```

For example:

```azurecli
az acr login --name mycontainerregistry082
```

The command returns `Login Succeeded` once completed:

```output
Login Succeeded
```

## Get application code

The sample application used in this tutorial is a basic voting app. The application consists of a front-end web component and a back-end Redis instance. The web component is packaged into a custom container image. The Redis instance uses an unmodified image from Docker Hub.

Use [git](https://git-scm.com/downloads) to clone the sample application to your development environment:

```console
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
```

Change into the cloned directory.

```console
cd azure-voting-app-redis
```

Inside the directory is the application source code and a pre-created Docker compose file, docker-compose.yaml.

## Modify Docker compose file

Open docker-compose.yaml in a text editor. The file configures the `azure-vote-back` and `azure-vote-front` services.

```yml
version: '3'
services:
  azure-vote-back:
    image: mcr.microsoft.com/oss/bitnami/redis:6.0.8
    container_name: azure-vote-back
    environment:
      ALLOW_EMPTY_PASSWORD: "yes"
    ports:
        - "6379:6379"

  azure-vote-front:
    build: ./azure-vote
    image: mcr.microsoft.com/azuredocs/azure-vote-front:v1
    container_name: azure-vote-front
    environment:
      REDIS: azure-vote-back
    ports:
        - "8080:80"
```

In the `azure-vote-front` configuration, make the following two changes:

1. Update the `image` property in the `azure-vote-front` service. Prefix the image name with the login server name of your Azure container registry, \<acrName\>.azurecr.io. For example, if your registry is named *myregistry*, the login server name is *myregistry.azurecr.io* (all lowercase), and the image property is then `myregistry.azurecr.io/azure-vote-front`.
1. Change the `ports` mapping to `80:80`. Save the file.

The updated file should look similar to the following:

```yml
version: '3'
services:
  azure-vote-back:
    image: mcr.microsoft.com/oss/bitnami/redis:6.0.8
    container_name: azure-vote-back
    environment:
      ALLOW_EMPTY_PASSWORD: "yes"
    ports:
        - "6379:6379"

  azure-vote-front:
    build: ./azure-vote
    image: myregistry.azurecr.io/azure-vote-front
    container_name: azure-vote-front
    environment:
      REDIS: azure-vote-back
    ports:
        - "80:80"
```

By making these substitutions, the `azure-vote-front` image you build in the next step is tagged for your Azure container registry, and the image can be pulled to run in Azure Container Instances.

## Run multi-container application locally

Run [docker-compose up](https://docs.docker.com/compose/reference/up/), which uses the sample `docker-compose.yaml` file to build the container image, download the Redis image, and start the application:

```console
docker-compose up --build -d
```

When completed, use the [docker images](https://docs.docker.com/engine/reference/commandline/images/) command to see the created images. Three images have been downloaded or created. The `azure-vote-front` image contains the front-end application, which uses the `uwsgi-nginx-flask` image as a base. The `redis` image is used to start a Redis instance.

```
$ docker images

REPOSITORY                                TAG        IMAGE ID            CREATED             SIZE
myregistry.azurecr.io/azure-vote-front    latest     9cc914e25834        40 seconds ago      944MB
mcr.microsoft.com/oss/bitnami/redis       6.0.8      3a54a920bb6c        4 weeks ago          103MB
tiangolo/uwsgi-nginx-flask                python3.6  788ca94b2313        9 months ago        9444MB
```

Run the [docker ps](https://docs.docker.com/engine/reference/commandline/ps/) command to see the running containers:

```
$ docker ps

CONTAINER ID        IMAGE                                      COMMAND                  CREATED             STATUS              PORTS                           NAMES
82411933e8f9        myregistry.azurecr.io/azure-vote-front     "/entrypoint.sh /sta…"   57 seconds ago      Up 30 seconds       443/tcp, 0.0.0.0:80->80/tcp   azure-vote-front
b62b47a7d313        mcr.microsoft.com/oss/bitnami/redis:6.0.8  "/opt/bitnami/script…"   57 seconds ago      Up 30 seconds       0.0.0.0:6379->6379/tcp          azure-vote-back
```

To see the running application, enter `http://localhost:80` in a local web browser.

After trying the local application, run [docker-compose down](https://docs.docker.com/compose/reference/down/) to stop the application and remove the containers.

```console
docker-compose down
```

## Push image to container registry

To deploy the application to Azure Container Instances, you need to push the `azure-vote-front` image to your container registry. Run [docker-compose push](https://docs.docker.com/compose/reference/push) to push the image:

```console
docker-compose push
```

It can take a few minutes to push to the registry.

To verify the image is stored in your registry, run the [az acr repository show](/cli/azure/acr/repository#az_acr_repository_show) command:

```azurecli
az acr repository show --name <acrName> --repository azure-vote-front
```

## Create Azure context

To use Docker commands to run containers in Azure Container Instances, first log into Azure:

```bash
docker login azure
```

When prompted, enter or select your Azure credentials.


Create an ACI context by running `docker context create aci`. This context associates Docker with an Azure subscription and resource group so you can create and manage container instances. For example, to create a context called *myacicontext*:

```
docker context create aci myacicontext
```

When prompted, select your Azure subscription ID, then select an existing resource group or **create a new resource group**. If you choose a new resource group, it's created with a system-generated name. Azure container instances, like all Azure resources, must be deployed into a resource group. Resource groups allow you to organize and manage related Azure resources.


Run `docker context ls` to confirm that you added the ACI context to your Docker contexts:

```
docker context ls
```

## Deploy application to Azure Container Instances

Next, change to the ACI context. Subsequent Docker commands run in this context.

```console
docker context use myacicontext
```

Run `docker compose up` to start the application in Azure Container Instances. The `azure-vote-front` image is pulled from your container registry and the container group is created in Azure Container Instances.

```console
docker compose up
```

In a short time, the container group is deployed. Sample output:

```
[+] Running 3/3
 ⠿ Group azurevotingappredis  Created                          3.6s
 ⠿ azure-vote-back            Done                             10.6s
 ⠿ azure-vote-front           Done                             10.6s
```

Run `docker ps` to see the running containers and the IP address assigned to the container group.

```console
docker ps
```

Sample output:

```
CONTAINER ID                           IMAGE                                         COMMAND             STATUS              PORTS
azurevotingappredis_azure-vote-back    mcr.microsoft.com/oss/bitnami/redis:6.0.8                         Running             52.179.23.131:6379->6379/tcp
azurevotingappredis_azure-vote-front   myregistry.azurecr.io/azure-vote-front                            Running             52.179.23.131:80->80/tcp
```

To see the running application in the cloud, enter the displayed IP address in a local web browser. In this example, enter `52.179.23.131`. The sample application loads, as shown in the following example:

:::image type="content" source="media/tutorial-docker-compose/azure-vote-aci.png" alt-text="Image of voting app in ACI":::

To see the logs of the front-end container, run the [docker logs](https://docs.docker.com/engine/reference/commandline/logs) command. For example:

```console
docker logs azurevotingappredis_azure-vote-front
```

You can also use the Azure portal or other Azure tools to see the properties and status of the container group you deployed.

When you finish trying the application, stop the application and containers with `docker compose down`:

```console
docker compose down
```

This command deletes the container group in Azure Container Instances.

## Clean-up

you can now stop all containers running locally, delete images, and delete azure resources you created for the lab.