# GitLab deployment on Bluemix Container Service - Kubernetes Version

## Overview
This project shows how a common multi-component application can be deployed
on the Bluemix container service with Kubernetes clusters. Each component runs in a separate container
or group of containers. 

Gitlab represents a typical multi-tier app and each component will have their own container(s). The microservice containers will be for the web tier, the state/job database with Redis and PostgreSQL as the database.


![Flow](images/gitlab_container.png)

## Included Components
- Bluemix container service
- Kubernetes
- GitLab
- NGINX
- Redis
- PostgreSQL

## Prerequisite

Create a Kubernetes cluster with IBM Bluemix Container Service. 

If you have not setup the Kubernetes cluster, please follow the [Creating a Kubernetes cluster](https://github.com/IBM/container-journey-template) tutorial.

## QuickStart

Run the following commands or run the quickstart script `bash quickstart.sh` with your Kubernetes cluster.

```bash
$ kubectl create -f postgres.yaml
service "postgres" created
deployment "postgres" created
$ kubectl create -f redis.yaml
service "redis" created
deployment "redis" created
$ kubectl create -f gitlab.yaml
service "gitlab" created
deployment "gitlab" created
```

After you created all the services and deployments, wait for 3 to 5 minutes and run the following commands to get your public IP and NodePort number.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.241.106   Ready     23h
$ kubectl get svc gitlab
NAME      CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
gitlab    10.10.10.90   <nodes>       80:30911/TCP   16h
```

Congratulation. Now you can use the link **http://[IP]:[port number]** to access your gitlab site.

> Note: For the above example, the link would be http://169.47.241.106:30911  since its IP is 169.47.241.106 and its port number is 30911. 

## Troubleshooting

To delete all your services and deployments, run

```bash
$ kubectl delete deployment,service -l app=gitlab
deployment "gitlab" deleted
deployment "postgres" deleted
deployment "redis" deleted
service "gitlab" deleted
service "postgres" deleted
service "redis" deleted
```

# License
[Apache 2.0](LICENSE.txt)
