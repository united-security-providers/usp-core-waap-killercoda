&#127919; In this step you will:

* Configure your CoreWaapService instance
* Again access prometheus debug endpoint page
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

Applying a virtual patch on a web application firewall provides immediate protection against known vulnerabilities without requiring downtime or changes to the application's source code. It's a cost-effective, temporary solution that reduces the risk of attacks until a permanent patch on the application source code can be implemented.

### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Having the USP Core WAAP operator installed and ready to go, you can now configure the USP Core WAAP `instance`.

You will setup an instance of Core WAAP using the created ConfigMap using:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: prometheus-usp-core-waap
  namespace: prometheus
spec:
  routes:
    - match:
        path: /
        pathType: PREFIX
      backend:
        address: prometheus
        port: 9090
        protocol:
          selection: h1
```{{copy}}

Using this updated configuration the HTTP Error Codes 500 - 599 are now mapped to the configured custom error page.

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/prometheus-usp-core-waap created
```

</details>
<br />

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

Now re-check if a Core WAAP instance is active in the `prometheus` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                       AGE
prometheus  prometheus-usp-core-waap   59s
```

</details>
<br />

Check if a Core WAAP Pod is running:

```shell
kubectl get pods \
  -l app.kubernetes.io/name=usp-core-waap \
  --all-namespaces
```{{exec}}


<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                                       READY   STATUS    RESTARTS   AGE
prometheus  prometheus-usp-core-waap-7849dbf5fd-4jt8c  1/1     Running   0          43s
```

</details>
<br />

> &#8987; Wait until the USP Core WAAP pod is running before trying to access the API in the next step (otherwise you'll get a HTTP 502 response)!

<details>
<summary>solution</summary>

Create the Core WAAP instance using:

```shell
kubectl apply -f prometheus-core-waap.yaml
```{{exec}}

and wait for its readiness:

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap \
  -n prometheus \
  --for='condition=Ready'
```{{exec}}

</details>
<br />

### Again access prometheus debug endpoint page

...

### Inspect USP Core WAAP logs
