&#127919; In this step you will:

* Prepare the virtual patch
* Configure your CoreWaapService instance
* Again access prometheus debug endpoint page
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

Applying a virtual patch provides immediate protection against known vulnerabilities without requiring downtime or changes to the application's source code. It's a cost-effective, temporary solution that reduces the risk of attacks until a permanent patch on the application source code can be implemented.

**A virtual patch is not a replacement for an actual application fix but serves as a quick and generic solution to mitigate a vulnerability until an application update can be applied**

### Prepare the virtual patch

Using the `crs.customRequestBlockingRules` attribute of a `CoreWaapService` kubernetes resource the default [OWASP Core Rule Set](https://owasp.org/www-project-modsecurity-core-rule-set/) rules can be extended. In our case we will add a rule preventing access to the problematic `/debug/pprof` endpoint provided by prometheus application.

Rules are written using [OWASP Coraza Seclang](https://coraza.io/docs/seclang/) and an example rule preventing access to the URI `/debug/pprof` could look like:

```shell
SecRule REQUEST_URI "^/debug/pprof" \
 "id:300000,
 phase:2,deny,status:403,
 t:lowercase,
 msg:'Access to /debug/pprof denied'"
```

As explained in the [Core WAAP documentation](https://docs.united-security-providers.ch/usp-core-waap/crs-virtual-patch/) rules should be configured using [folded style](https://yaml.org/spec/1.2.2/#813-folded-style) strings with [stripping chomping indicator](https://yaml.org/spec/1.2.2/#8112-block-chomping-indicator) (i.e. >-) and no extra indentation or trailing slashes and **must use an ID between 300000 and 399999**, like:

```yaml
...
spec:
  crs:
    customRequestBlockingRules:
      - name: "Deny pprof access"
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

In the next section we will configure the Core WAAP instance accordingly using this `virtual patch` against the problematic `pprof` endpoint.

### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Having the USP Core WAAP operator installed and ready to go, you can configure the USP Core WAAP `instance` using the prepared `virtual patch` rule we applying the following `CoreWaapService` resource configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: prometheus-usp-core-waap
  namespace: prometheus
spec:
  crs:
    customRequestBlockingRules:
      - name: "Deny pprof access"
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
        address: prometheus-server
        port: 80
        protocol:
          selection: h1
```{{copy}}

In addition to the `routes` configuration we enable a `customRequestBlockingRules` config preventing access to the problematic `/debug/pprof` endpoint and apply this config.

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

Try to access the [pprof debug page]({{TRAFFIC_HOST1_80}}/debug/pprof) again. As you now access the prometheus application via Core WAAP and applying the virtual patch to deny access to this endpoint you will get a `HTTP 403 - Forbidden` response. You could also use `curl` to validate this:

```shell
curl -sv localhost/debug/pprof
```{{exec}}

<details>
<summary>example command output</summary>

```shell
*   Trying 127.0.0.1:80...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 80 (#0)
> GET /debug/pprof HTTP/1.1
> Host: localhost
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 403 Forbidden
< date: Wed, 18 Dec 2024 07:56:37 GMT
< server: envoy
< content-length: 0
< 
* Connection #0 to host localhost left intact
```

</details>
<br />

Feel free to make sure other aspects of the [prometheus web application]({{TRAFFIC_HOST1_80}}) still work as expected.

> &#128270; The virtual patch used in this scenario is a very simplified use-case and the [Coraza Seclang](https://coraza.io/docs/seclang/) is capable of filtering / blocking requests and responses based on various conditions (have a look at the [OWASP Core Rule Set](https://github.com/coreruleset/coreruleset/tree/main/rules) for more examples in addition to the Seclang documentation)

### Inspect USP Core WAAP logs

To get more details why a request was blocked you can look into the Core WAAP logs using:

```shell
kubectl logs \
  -n prometheus \
  -l app.kubernetes.io/name=usp-core-waap
```{{exec}}

The coraza log messages are split into two parts: First part prior to `coraza-vm:` containing the generic envoy log information indicating what module is taking action, which in our use-case is the [coraza web application firewall](https://github.com/corazawaf/coraza) module and the second part which is the actual payload log formatted as JSON.

Using the following command you can extract the JSON part filtering for our `/debug/pprof` request getting the details about actions taken by USP Core WAAP:

```shell
kubectl logs \
  -n prometheus \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=1000 \
  | grep "\[critical\]\[golang\].*/debug/pprof" \
  | sed -e 's/\[.*\] {/{/' \
  | jq
```{{exec}}

This command selects the Core WAAP pod via label `app.kubernetes.io/name=usp-core-waap` in the respective namespace and explicitly filters for the `/debug/pprof` request and at last parses the JSON using `jq` command-line utility.

That's it! You have successfully applied a `virtual patch` mitigating the mentioned DoS attack for the `pprof` endpoint.
