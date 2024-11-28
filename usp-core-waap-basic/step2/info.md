&#127919; In this step you will:

* Learn Kubernetes basics (Ingress / Service / Pod)
* Verify the USP Core WAAP operator is installed and ready

### Kubernetes basics (Ingress / Service / Pod)

Have a look at the Kubernetes Ingress / Service / Pod architecture:

![kuberntes ingress / svc / pod](./kubernetes_ingress_svc_pod.png)

> &#128270; For this demo setup we are using a simple port-forward instead of an ingress resource.

### Verify the USP Core WAAP operator is installed and ready

You will now verify the **USP Core WAAP operator** is installed. The setup used will be slightly different in terms of traffic as it will be handled by USP Core WAAP which (acting as a reverse-proxy / WAF) will query the backend applicatoin itself:

![USP Core WAAP setup](./kubernetes_core_waap.png)

To make use of Core WAAP, the USP Core WAAP operator has to be installed and running. This is out of scope for this lecture and therefore already prepared.

To check if the operator is running you can use the following command:

```shell
kubectl get pods \
  -n usp-core-waap-operator
```{{exec}}

<details>
<summary>example command output

```shell
NAME                                 READY   STATUS    RESTARTS        AGE
core-waap-operator-744f7c8b8-7kfbs   1/1     Running   1 (2m21s ago)   2m34s
```

</details>
<br />

The operator listens to resources of kind `CoreWaapService`. As soon as such a **CustomResource** is configured, the operator creates the further required resources to run an USP Core WAAP instance.

To check if a Core WAAP resource exists you can run:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

There are none yet (`No resources found`) and also there are no core-waap PODs yet (they all get the label 'app.kubernetes.io/name=usp-core-waap'):

```shell
kubectl get pods \
  -l app.kubernetes.io/name=usp-core-waap \
  --all-namespaces
```{{exec}}

Now you can go ahead and change this in the next step as the USP Core WAAP Operator is ready you can configure a `CoreWaapService` now!
