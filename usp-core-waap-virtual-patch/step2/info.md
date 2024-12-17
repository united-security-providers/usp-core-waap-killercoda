&#127919; In this step you will:

* Prepare the virtual patch
* Configure your CoreWaapService instance
* Again access prometheus debug endpoint page
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

Applying a virtual patch on a web application firewall provides immediate protection against known vulnerabilities without requiring downtime or changes to the application's source code. It's a cost-effective, temporary solution that reduces the risk of attacks until a permanent patch on the application source code can be implemented.

### Prepare the virtual patch

Using the `crs.customRequestBlockingRules` attribute the default [OWASP Core Rule Set](https://owasp.org/www-project-modsecurity-core-rule-set/) rules can be extended. In our case we will add a rule preventing access to the problematic `/debug/pprof` endpoint provided by prometheus.

Rules are written using [OWASP Coraza Seclang](https://coraza.io/docs/seclang/) and an example rule preventing access to the URI `/debug/pprof` could look like:

```shell
SecRule REQUEST_URI "^/debug/pprof" "id:300000,phase:2,t:lowercase,deny,status:403,msg:'Access to /debug/pprof denied'"
```

As explained in the [documentation](https://united-security-providers.github.io/crs-virtual-patch/) rules should be configured using [folded style](https://yaml.org/spec/1.2.2/#813-folded-style) strings with [stripping chomping indicator](https://yaml.org/spec/1.2.2/#8112-block-chomping-indicator) (i.e. >-) and no extra indentation or training slashes and **use an ID between 300000 and 399999**, like:

```yaml
...
spec:
  crs:
    customRequestBlockingRules:
      - name "Deny pprof access"
        secLangExpression: >-
          SecRule REQUEST_URI "^/debug/pprof"
          "id:300000,
          phase:2,deny,status:403,
          t:lowercase,
          msg:'Access to /debug/pprof denied',
          logdata:'denied request to /debug/pprof endpoint',
          severity:'CRITICAL'"
...
```

In the next section we will configure the Core WAAP instance accordingly.

### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Having the USP Core WAAP operator installed and ready to go, you can now configure the USP Core WAAP `instance`.

Having prepared the `virtual patch` rule we apply the following `CoreWaapService` `configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: prometheus-usp-core-waap
  namespace: prometheus
spec:
  crs:
    customRequestBlockingRules:
      - name "Deny pprof access"
        secLangExpression: >-
          SecRule REQUEST_URI "^/debug/pprof"
          "id:300000,
          phase:2,deny,status:403,
          t:lowercase,
          msg:'Access to /debug/pprof denied',
          logdata:'denied request to /debug/pprof endpoint',
          severity:'CRITICAL'"
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

In addition to the `routes` configuration we enable a `customRequestBlockingRules` config preventing access to the problematic `/debug/pprof` endpoint.

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
