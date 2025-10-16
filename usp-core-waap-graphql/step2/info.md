<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your `CoreWaapService` instance
* Again access the LLDAP application
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

### Configure your `CoreWaapService` instance

> &#128270; If you are inexperienced with Kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Before we can configure the GraphQL specific features we need to prepare the LLDAP Schema definition as a Kubernetes `ConfigMap` used by USP Core WAAP later.

To create the `ConfigMap` use the following command:

```shell
kubectl create \
  configmap lldap-graphql-schema \
  --from-file lldap-schema.graphql \
  -n lldap
```{{exec}}

<details>
<summary>example command output</summary>

```shell
configmap/lldap-schema created
```

</details>
<br />

Having the USP Core WAAP operator already installed and ready to go, you can configure the USP Core WAAP `instance` now by applying the following `CoreWaapService` resource configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: lldap-usp-core-waap
  namespace: lldap
spec:
  csrfPolicy:
    enabled: false
  coraza:
    crs:
      defaultEnabled: false
    graphql:
      configs:
        - name: lldap-ref
          schemaSource:
            configMap: lldap-graphql-schema
            key: lldap-schema.graphql
  routes:
    - match:
        path: /
        pathType: PREFIX
      coraza:
        graphql:
          enabled: true
          ref: lldap-ref
          mode: BLOCK
      backend:
        address: lldap
        port: 17170
        protocol:
          selection: h1
```{{copy}}

(you need to apply this content using "kubectl apply -f ..." or see "hint" or "solution")

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/lldap-core-waap created
```

</details>
<br />

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

> &#128270; Since USP Core WAAP also features [Cross Site Request Forgery (CSRF)](https://owasp.org/www-community/attacks/csrf) protection in this demo scenario that feature is disabled (via setting `spec.csrfPolicy.enabled`) to allow local curl http post requests! Similarly we don't want to see BLOCKs executed by the OWASP Core Rule Set which is why the `spec.coraza.crs.defaultEnabled` option is disabled too.

This resource uses the default security configuration for [allowIntrospection](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespeccorazagraphqlconfigsindex) and by that preventing introspection queries.

Now check if the created Core WAAP instance is active in the `lldap` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                       AGE
lldap       lldap-usp-core-waap        59s
```

</details>
<br />

And check if a Core WAAP Pod is running:

```shell
kubectl get pods \
  -l app.kubernetes.io/name=usp-core-waap \
  --all-namespaces
```{{exec}}


<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                                       READY   STATUS    RESTARTS   AGE
lldap       lldap-usp-core-waap-7849dbf5fd-4jt8c       1/1     Running   0          43s
```

</details>
<br />

> &#8987; Wait until the USP Core WAAP Pod is running before trying to access the backend in the next step (otherwise you'll get a HTTP 502 response)!

<details>
<summary>solution</summary>

Prepare the required ConfigMap using:

```shell
kubectl create \
  configmap lldap-graphql-schema \
  --from-file lldap-schema.graphql \
  -n lldap
```{{exec}}

Then create the Core WAAP instance using:

```shell
kubectl apply -f lldap-core-waap.yaml
```{{exec}}

and wait for its readiness:

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap \
  -n lldap \
  --for='condition=Ready'
```{{exec}}

</details>
<br />

### Again access the LLDAP application

This time we will access the [LLDAP](https://github.com/lldap/lldap/) application via USP Core WAAP and re-evaluate the responses. The same backend application code is in use (verify using `kubectl get pods -n lldap` and confirm POD runtime). Also note the changed Port previously using port 8080 (direct LLDAP application access) and now accessing using default port 80 (USP Core WAAP acting as a reverse proxy).

Now USP Core WAAP features GraphQL filtering enabling to **prevent introspection queries** configured via `spec.coraza.graphql.allowIntrospection` setting (disabled by default, see [documentation](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespeccorazagraphql)). As we already did in the previous step we will again execute an introspection query against the LLDAP GraphQL API:

```shell
curl -v 'http://localhost/api/graphql' \
   -H 'Content-Type: application/json' \
   --silent \
   --cookie "token=$LLDAP_TOKEN" \
   --data '{"query": "query { __schema { types { name }} }"}'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
* Host localhost:80 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:80...
* Connected to localhost (::1) port 80
> POST /api/graphql HTTP/1.1
> Host: localhost:80
> User-Agent: curl/8.5.0
> Accept: */*
> Cookie: token=...
> Content-Type: application/json
> Content-Length: 49
>
} [49 bytes data]
< HTTP/1.1 403 Forbidden
< date: Tue, 14 Oct 2025 13:42:42 GMT
< server: envoy
< content-length: 0
<
* Connection #0 to host localhost left intact
```

</details>
<br />

Now since USP Core WAAP is configured to block introspection queries, this query is denied by HTTP response 403!

### Inspect USP Core WAAP logs

To get more details on why a request was blocked, you can look into the Core WAAP logs using:

```shell
kubectl logs \
  -n lldap \
  -l app.kubernetes.io/name=usp-core-waap
```{{exec}}

Using the following command, you can filter for events of type 'removing request header' and, by parsing the log, see the details of the JSON payload:

```shell
kubectl logs \
  -n lldap \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep 'GraphQL introspection query detected' \
  | sed -e 's/\[.*\] {/{/' \
  | jq
```{{exec}}

<details>
<summary>example command output</summary>

```shell
{
  "request.path": "/api/graphql",
  "crs.violated_rule": {
    "id": 110000,
    "category": "",
    "severity": "EMERGENCY",
    "data": "",
    "message": "GraphQL introspection query detected",
    "matched_data": "TX",
    "matched_data_name": "envoy_route_index",
    "tags": []
  },
  "client.address": "127.0.0.1",
  "transaction.id": "3b13b0d1-2fc7-4b53-8805-50e8010856af",
  "crs.version": "",
  "request.id": "3b13b0d1-2fc7-4b53-8805-50e8010856af"
}
```

</deatils>
<br />

This command selects the Core WAAP Pod via label `app.kubernetes.io/name=usp-core-waap` in the respective namespace. It also parses the log message to show the relevant section of `GraphQL introspection query detected` message (JSON formatted).

That's it! You have successfully prevented a GraphQL introspection query **using the USP Core WAAP**. Next we will have a look at query depth, batch size and complexity and how to safeguard against unexpected complex queries.
