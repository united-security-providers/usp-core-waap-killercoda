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
  headerFilter:
    defaultFilterRef: petstore-headers
    filters:
      - name: petstore-headers
        request:
          allow:
            - api_key
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

> &#128270; The OpenAPI validation is configured via `spec.openapi` and referenced by the route via `openapiRefs` (see [OpenAPI validation documentation](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/openapi-validation/)). As the swagger petstore API requires an `api_key` request header (more on that later), this header is additionally allowed by the [header filter](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/header-filtering/) via `spec.headerFilter` (otherwise it would be removed by the default header filtering).

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
< date: Fri, 08 Nov 2024 09:58:30 GMT
< server: envoy
< connection: close
< content-length: 0
<
* Closing connection
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
127.0.0.1 - - [08/Nov/2024:09:41:17 +0000] "GET / HTTP/1.1" 200 3851
127.0.0.1 - - [08/Nov/2024:09:41:18 +0000] "GET /api/pet/1 HTTP/1.1" 200 -
127.0.0.1 - - [08/Nov/2024:09:42:18 +0000] "GET /api/pet/cat1 HTTP/1.1" 404 -
```

</details>
<br />

Now make sure a valid petstore API call still works:

```shell
curl -sv http://127.0.0.1:30090/api/pet/1
```{{exec}}

<details>
<summary>example command output</summary>

```shell
*   Trying 127.0.0.1:30090...
* Connected to 127.0.0.1 (127.0.0.1) port 30090
> GET /api/pet/1 HTTP/1.1
> Host: 127.0.0.1:30090
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 403 Forbidden
< date: Fri, 08 Nov 2024 10:00:51 GMT
< server: envoy
< connection: close
< content-length: 0
<
* Closing connection
```

</details>
<br />

**Wait! Why is that also getting an HTTP 403 response?!**

Well, the configured OpenAPI specification includes an [API Keys](https://swagger.io/docs/specification/v3_0/authentication/api-keys/) section which is not enforced by the swagger petstore backend application but is now via USP Core WAAP! In order to successfully query pets we need to send an `api_key` header:

```shell
curl -s -H 'api_key: anything' http://127.0.0.1:30090/api/pet/1 | jq
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

What about our first invalid API call, this was blocked because of the missing security header so let's confirm it is also blocked when that header is sent:

```shell
curl -sv -H 'api_key: anything' http://127.0.0.1:30090/api/pet/waapcat1
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
< date: Fri, 08 Nov 2024 09:58:30 GMT
< server: envoy
< connection: close
< content-length: 0
<
* Closing connection
```

</details>
<br />

As you can see even the response is the same (`HTTP 403 Forbidden`) but the reasons were different as you will see inspecting the logs in the next section.

### Inspect USP Core WAAP logs

How to get more insight in why a request was blocked by the USP Core WAAP OpenAPI validation feature? Let's have a look at the logs!

The OpenAPI validation is executed within the USP Core WAAP container itself, logging the validation errors which caused a request to be blocked. Use the following command to filter for the OpenAPI validation log lines:

```shell
kubectl logs \
  -n petstore \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep 'validation errors'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
[2026-10-29 09:58:30.130000][info][23][misc][openapi.go:120][openapi] msg="RequestHeaders: GET /api/pet/waapcat1, validation errors: [Error: API Key api_key not found in header, Reason: API Key not found in http header for security scheme 'apiKey' with type 'header', Line: 331, Column: 11 Error: Path parameter 'petId' is not a valid number, Reason: The path parameter 'petId' is defined as being a number, however the value 'waapcat1' is not a valid number, Line: 301, Column: 13]"
[2026-10-29 10:00:52.250000][info][23][misc][openapi.go:120][openapi] msg="RequestHeaders: GET /api/pet/1, validation errors: [Error: API Key api_key not found in header, Reason: API Key not found in http header for security scheme 'apiKey' with type 'header', Line: 331, Column: 11]"
[2026-10-29 10:01:15.840000][info][23][misc][openapi.go:120][openapi] msg="RequestHeaders: GET /api/pet/waapcat1, validation errors: [Error: Path parameter 'petId' is not a valid number, Reason: The path parameter 'petId' is defined as being a number, however the value 'waapcat1' is not a valid number, Line: 301, Column: 13]"
```

</details>
<br />

Note the first blocked request was missing the `api_key` header **and** used an invalid `petId`, the second one was only missing the `api_key` header while the third one (sending the `api_key` header) was only blocked due to the invalid `petId`.

> &#128270; See [Logs and Metrics](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/operation/logs-metrics/) for details on the USP Core WAAP log format.

> &#128270; While fixing vulnerabilities / writing secure application code is imminent USP Core WAAP can help you out taking the time it takes to fix all vulnerabilities and giving you an additional layer of security!

That's it! Protecting an application through an OpenAPI specification brings a lot of additional security as demonstrated here not just with incorrect API requests but also about missing security headers (specified in API but mistakenly not enforced by the application).
