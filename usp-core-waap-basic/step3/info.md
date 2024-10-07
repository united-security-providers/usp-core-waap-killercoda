### Configure your CoreWaapService instance

(note: if you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide)

Having the Core WAAP operator installed and ready to go, you can configure the USP Core WAAP instance to protect the Juiceshop web app:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
  namespace: juiceshop
spec:
  websocket: True
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: juiceshop
        port: 8000
        protocol:
          selection: h1
```{{copy}}

You can now re-check if a Core WAAP instance is active in the juiceshop namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

Check if also a Core WAAP Pod is running:

```shell
kubectl get pods -l app.kubernetes.io/name=usp-core-waap --all-namespaces
```{{exec}}

**wait until the Core WAAP pod is running before trying to access the webapplication in the next step (otherwise you'll get a HTTP 502 response)**

<details>
<summary>hint</summary>

There is a file in your home directory with an example `corewaapservice` definition ready to be applied using `kubectl apply -f` ...

</details>

### Access juiceshop web application via USP Core WAAP

We changed the port forwarding accordingly that the traffic to the [juiceshop webapplication]({{TRAFFIC_HOST1_8080}}) is now routed **via USP Core WAAP**. Try if you still can exploit the vulnerability in the login dialog using the previous SQL-injection (remember email `' OR true;` and any password except empty)...

The described exploit is now blocked by the Core WAAP. If you open the browser developer tool, you can see that the login request is answered with the response status 403.

### Inspect the actions taken by USP Core WAAP

To see the actual block you can filter the USP Core WAAP Pod logs for 'APPLICATION-ATTACK-SQLI' (refer to the [OWASP Core Ruleset documentation](https://coreruleset.org/docs/rules/rules/)) while you are trying to login using the mentioned SQL-injection

```shell
kubectl -n juiceshop logs -f -l app.kubernetes.io/name=usp-core-waap |grep APPLICATION-ATTACK-SQLI
```{{exec}}

<details>
<summary>solution</summary>

First create the core-waap instance using

```shell
kubectl apply -f juiceshop-core-waap.yaml
```{{exec}}

and wait for its readiness...

```shell
kubectl wait pods -l app.kubernetes.io/name=usp-core-waap -n juiceshop --for='condition=Ready'
```{{exec}}

then at last access the [juiceshop webapplication]({{TRAFFIC_HOST1_8080}}) again and try to exploit the SQL-injection vulnerability again
</details>
