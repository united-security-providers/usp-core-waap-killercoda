>this scenario uses the official `bkimminich/juice-shop` docker image provided by the OWASP Juice Shop project and will run it as pod workload.

this step will guide you to setup the [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) application run as a kubernetes workload

initially there is no workload running in default namespace as you can check using:

```shell
kubectl get pods
```{{exec}}

in order for you to easily setup the application there is an example pod-yaml available via `~/pod.yaml` for you, go ahead and apply it!

(if you decide to manually create the pod make sure to name it `juiceshop` and expose port 3000)

now re-check if there are running workloads (execute multiple times if needed):

```shell
kubectl get pods
```{{exec}}

<details>

<summary>show me the solution</summary>

using `kubectl` apply the provided pod-yaml definition

```shell
kubectl apply -f pod.yaml
```{{exec}}

</details>
