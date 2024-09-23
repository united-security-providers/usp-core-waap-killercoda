### kubernetes basics (ingress / service / pod)

let's have a look at the kubernetes ingress / service / pod architecture:

![kuberntes ingress / svc / pod](./kubernetes_ingress_svc_pod.png)

using the killercoda platfrom we will replace the ingress by using a [port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) for simplicity and initially have [accessed the juiceshop]({{TRAFFIC_HOST1_80}}) via the juiceshop service (pre-installed for you)

### setup USP Core Waap instance

we will now setup a **USP Core Waap instance** and then access the Juiceshop web application via core waap instead and test if we still can execute an SQL injection in the next step. The setup used will be slightly different in terms of traffic as it will be handled by USP Core Waap which (acting as a reverse-proxy / WAF) will query the Juiceshop application itself:

![USP Core Waap setup](./kubernetes_core_waap.png)

the USP Core Waap operator has been pre-installed in namespace `usp-core-waap-operator` for you as you can verify using

```shell
kubectl get pods -n usp-core-waap-operator
```{{exec}}

and it awaits your wishes to be configured via the newly available kubernetes kind `corewaapservice` let's see if there are any instances yet...

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

there are none yet and also there are no core-waap PODs yet (they all get the label 'app.kubernetes.io/name=usp-core-waap')

```shell
kubectl get pods -l app.kubernetes.io/name=usp-core-waap --all-namespaces
```{{exec}}

now let's go ahead and change this in the next step as the USP Core Waap Operator is ready we can configure a `corewaapservice` now!
