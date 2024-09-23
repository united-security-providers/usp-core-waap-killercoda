### configure your corewaapservice instance

having the operator installed and ready to go we can configure the USP Core Waap instance to protect our juiceshop web app:

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

if you apply this kubernetes resource definition (note that it will be applied to the juiceshop namespace) and re-check for USP Core Waap instances using

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

and the USP Core Waap POD within juiceshop namespace

```shell
kubectl get pods -l app.kubernetes.io/name=usp-core-waap --all-namespaces
```{{exec}}

<details>
<summary>hint</summary>

there is a file in you home directory with an example `corewaapservice` definition ready to be applied using `kubectl apply -f` ...

</details>


### access juiceshop web application via USP Core Waap

at last using a port-forward now access the [juiceshop webapplication]({{TRAFFIC_HOST1_8080}}) **now  via USP Core Waap** and re-try if you still can bypass the login using the previous SQL-injection (remember email `' OR true;` and any password except empty)...it now seems the application does not respond to your login request anymore (unless you use valid login data of course)!

### inspect the actions taken by USP Core Waap

to see the actual block you can filter the USP Core Waap Pod Logs for 'APPLICATION-ATTACK-SQLI' (refer to the [OWASP Core Ruleset documentation](https://coreruleset.org/docs/rules/rules/)) while you are trying to login using the mentioned SQL-injection

```shell
kubectl -n juiceshop logs -f -l app.kubernetes.io/name=usp-core-waap |grep APPLICATION-ATTACK-SQLI
```{{exec}}

<details>
<summary>solution</summary>

first create the core-waap instance using

```shell
kubectl apply -f juiceshop-core-waap.yaml
```{{exec}}

and wait for its readiness...

```shell
kubectl wait pods -l app.kubernetes.io/name=usp-core-waap -n juiceshop --for='condition=Ready'
```{{exec}}
</details>
