> if you manually create the service name it `juiceshop`!

to access a kubernetes deployed application a service is required.
in order for you to easily setup the service there is an example service-yaml available via `~/svc.yaml` for you, go ahead and apply it!
(if you manually create the servcie note that the juiceshop pod exposes port 3000)

check services using

```shell
kubectl get services
```{{exec}}

<details>

<summary>show me the solution</summary>

```shell
kubectl apply -f svc.yaml
```{{exec}}

</details>
