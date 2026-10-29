<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your `CoreWaapService` instance to protect the backend
* Access the swagger petstore API via USP Core WAAP
* Inspect USP Core WAAP logs

### Configure your CoreWaapService instance to protect the backend

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide

Having the Core WAAP operator installed and ready to go, you can configure the USP Core WAAP instance to protect the swagger petstore API.

First you will setup the kubernetes `Configmap` providing the [OpenAPI specification](https://swagger.io/docs/specification/v3_0/basic-structure/) for the swagger petstore API used by the USP Core WAAP instance to validate requests:

```shell
kubectl apply -f openapi-petstore-configmap.yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
configmap/openapi-petstore-v3 created
```

</details>
<br />

Next, you will setup an instance of USP Core WAAP using:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: petstore-usp-core-waap
  namespace: petstore
spec:
  coraza:
    crs:
      defaultEnabled: false
  openapi:
    - name: petstore-v3
      schemaSource:
        configMap: openapi-petstore-v3
        key: pet_store_v3.json
      scope:
        requestBody: true
        responseBody: false
  routes:
    - match:
        path: /api
        pathType: PREFIX
      openapiRefs:
        - petstore-v3
      backend:
        address: petstore
        port: 8080
        protocol:
          selection: h1
```{{copy}}

(for this demo scenario the OWASP Core Rule Set has been disabled via `spec.coraza.crs.defaultEnabled` to focus on OpenAPI validation)

> &#128270; The OpenAPI validation is configured via `spec.openapi` and referenced by the route via `openapiRefs` (see [OpenAPI validation documentation](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/openapi-validation/)).

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/petstore-usp-core-waap created
```

</details>
<br />

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

Now re-check if a USP Core WAAP instance is active in the `petstore` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                     AGE
petstore    petstore-usp-core-waap   59s
```

</details>
<br />

Check if USP Core WAAP Pod is running:

```shell
kubectl get pods \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --all-namespaces
```{{exec}}


<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                                      READY   STATUS    RESTARTS   AGE
petstore    petstore-usp-core-waap-78dbbc6d8c-6w7lr   1/1     Running   0          67s
```

</details>
<br />

> &#8987; Wait until the USP Core WAAP pod is running before trying to access the API in the next step (otherwise you'll get a HTTP 502 response or a connection error)!

Continue accessing the swagger petstore API in the next section (or consider the hidden solution in case you were not successful).

<details>
<summary>solution</summary>

First add the openapi configuration using

```shell
kubectl apply -f openapi-petstore-configmap.yaml
```{{exec}}

Next create the Core WAAP instance using

```shell
kubectl apply -f petstore-core-waap.yaml
```{{exec}}

Then wait for its readiness...

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  -n petstore \
  --for='condition=Ready' \
  --timeout 300s
```{{exec}}

</details>
<br />

### Access the swagger petstore API via USP Core WAAP

> &#128270; The traffic to the swagger petstore API is now **routed via USP Core WAAP** using node-port 30090 (instead of node-port 30080 used for direct backend access).

Again query a pet in an incorrect format as you did in the first step. This request should be blocked by USP Core WAAP (this incorrect request shall not reach the swagger petstore API backend):

```shell
curl -sv http://127.0.0.1:30090/api/pet/waapcat1
```{{exec}}

<details>
<summary>example command output</summary>

```shell
*   Trying 127.0.0.1:30090...
* Connected to 127.0.0.1 (127.0.0.1) port 30090
> GET /api/pet/waapcat1 HTTP/1.1
> Host: 127.0.0.1:30090
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 403 Forbidden
< date: Thu, 29 Oct 2026 12:09:05 GMT
< server: envoy
< content-length: 0
<
* Connection #0 to host 127.0.0.1 left intact
```

</details>
<br />

This time you'll get an `HTTP 403 (Forbidden)` response from USP Core WAAP and **you will not see any request in the backend** as this invalid call was intercepted!

```shell
kubectl -n petstore exec pod/petstore \
  -- /bin/bash -c "tail /var/log/*-requests.log"
```{{exec}}

> &#128270; Note that there is no `waapcat1` request seen on the swagger petstore API backend (compare against example command output below).

<details>
<summary>example command output</summary>

```shell
127.0.0.1 - - [29/Oct/2026:12:06:17 +0000] "GET / HTTP/1.1" 200 3851
127.0.0.1 - - [29/Oct/2026:12:06:18 +0000] "GET /api/pet/1 HTTP/1.1" 200 -
127.0.0.1 - - [29/Oct/2026:12:07:18 +0000] "GET /api/pet/cat1 HTTP/1.1" 404 -
```

</details>
<br />

Now make sure a valid petstore API call still works:

```shell
curl -s http://127.0.0.1:30090/api/pet/1 | jq
```{{exec}}

<details>
<summary>example command output</summary>

```json
{
  "id": 1,
  "category": {
    "id": 2,
    "name": "Cats"
  },
  "name": "Cat 1",
  "photoUrls": [
    "url1",
    "url2"
  ],
  "tags": [
    {
      "id": 1,
      "name": "tag1"
    },
    {
      "id": 2,
      "name": "tag2"
    }
  ],
  "status": "available"
}
```

</details>
<br />

Ahh...there it is again the familiar "furrr..."!

> &#128270; The used OpenAPI specification is available for detailed analysis via the [API definition for the swagger petstore](https://github.com/swagger-api/swagger-petstore/blob/master/src/main/resources/openapi.yaml) from the swagger-api project.

### Inspect USP Core WAAP logs

How to get more insight in why a request was blocked by the USP Core WAAP OpenAPI validation feature? Let's have a look at the logs!

The OpenAPI validation is executed within the USP Core WAAP container itself (logged by the `usp-openapi-validation` component). Use the following command to filter for failed OpenAPI request validations:

```shell
kubectl logs \
  -n petstore \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[usp-openapi-validation\].*request validation failed'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
[2026-10-29 12:09:05.187827][error][golang][0][openapi-validation/internal/filter/filter.go:148][usp-openapi-validation] msg="request validation failed" phase="DecodeHeaders" request.method="GET" request.url="/api/pet/waapcat1" request.errors="[Error: Path parameter 'petId' is not a valid integer, Reason: The path parameter 'petId' is defined as being an integer, however the value 'waapcat1' is not a valid integer, Validation Errors: [Reason: Value 'waapcat1' is not a valid integer], Line: 301, Column: 13]" request-id="caefa6cf-2efc-4a09-be85-bf1d27f9f5c1"
```

</details>
<br />

The `request.errors` field shows that the path parameter `petId` (defined as integer in the OpenAPI specification) did not match the provided value `waapcat1`, including the location (`Line` and `Column`) within the OpenAPI specification. To extract only the most relevant fields use:

```shell
kubectl logs \
  -n petstore \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[usp-openapi-validation\].*request validation failed' \
  | sed -E 's/.*request\.url="([^"]*)".*request\.errors="\[Error: ([^,]*),.*request-id="([^"]*)".*/request-id=\3 url=\1 : \2/'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
request-id=caefa6cf-2efc-4a09-be85-bf1d27f9f5c1 url=/api/pet/waapcat1 : Path parameter 'petId' is not a valid integer
```

</details>
<br />

Blocked requests are also recognizable in the access log lines (identified by the `[access]` component) via the `response.details` field:

```shell
kubectl logs \
  -n petstore \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[access\]' \
  | grep 'request.path="/api/pet/' \
  | grep -o -E 'request.path="[^"]*"|response.details="[^"]*"' \
  | paste - -
```{{exec}}

<details>
<summary>example command output</summary>

```shell
request.path="/api/pet/waapcat1"        response.details="usp_openapi_validation_request_parameters_invalid"
request.path="/api/pet/1"       response.details="via_upstream"
```

</details>
<br />

Note the `usp_openapi_validation_request_parameters_invalid` value indicating the request was blocked by the OpenAPI validation, while `via_upstream` indicates the response was sent by the swagger petstore API backend.

> &#128270; See [Logs and Metrics](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/operation/logs-metrics/) for details on the USP Core WAAP log format.

> &#128270; While fixing vulnerabilities / writing secure application code is imminent USP Core WAAP can help you out taking the time it takes to fix all vulnerabilities and giving you an additional layer of security!

That's it! Protecting an application through an OpenAPI specification brings a lot of additional security as demonstrated here by intercepting incorrect API requests before reaching the application.
