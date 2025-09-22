<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your CoreWaapService instance
* Again, access the vulnerable Next.js demo application
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

Applying USP Core WAAP provides immediate protection against CVE-2025-29927 without requiring downtime or changes to the application's source code. It's a cost-effective solution that reduces the risk of attacks until a permanent patch on the application source code can be implemented. In this particular example, the use of USP Core WAAP in its default configuration prevents exploitation of CVE-2025-29927!

**While the use of a USP Core WAAP serves as a quick and generic solution to mitigate a vulnerability until an application update can be applied this is no replacement to patch application code!**

### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Having the USP Core WAAP operator installed and ready to go, you can configure the USP Core WAAP `instance` by applying the following `CoreWaapService` resource configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: nextjs-app-usp-core-waap
  namespace: nextjs
spec:
  crs:
    mode: DETECT
  routes:
    - match:
        path: /
        pathType: PREFIX
      backend:
        address: nextjs-svc
        port: 3000
        protocol:
          selection: h1
```{{copy}}

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/nextjs-app-core-waap created
```

</details>
<br />

> &#10071; In order to show the header filtering feature here the Coraza Web Application firewall feature has been set to detect only (that feature too will block the crafted header "x-middleware-subrequest: middleware:middleware:middleware:middleware:middleware" by default to be recognizable in that case by the `HTTP 403` response)

This resource uses the default security configuration of header filtering where preconfigured by the `STANDARD` list of headers (see [documentation](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespecheaderfilteringrequest)) unknown headers are removed.

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

Now check if the created Core WAAP instance is active in the `nextjs` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                       AGE
nextjs      nextjs-app-usp-core-waap   59s
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
nextjs      nextjs-app-usp-core-waap-7849dbf5fd-4jt8c  1/1     Running   0          43s
```

</details>
<br />

> &#8987; Wait until the USP Core WAAP Pod is running before trying to access the backend in the next step (otherwise you'll get a HTTP 502 response)!

<details>
<summary>solution</summary>

Create the Core WAAP instance using:

```shell
kubectl apply -f nextjs-app-core-waap.yaml
```{{exec}}

and wait for its readiness:

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap \
  -n nextjs \
  --for='condition=Ready'
```{{exec}}

</details>
<br />

### Again access the vulnerable Next.js demo application

This time we will access the [Next.js demo application](https://github.com/lirantal/vulnerable-nextjs-14-CVE-2025-29927) via USP Core WAAP and re-evaluate the responses. The same backend application code is in use (verify using `kubectl get pods -n nextjs` and confirm POD runtime).


```shell
curl -v http://localhost/api/hello | jq
```{{exec}}

<details>
<summary>example command output</summary>

```shell
* Host localhost:80 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:80...
* connect to ::1 port 80 from ::1 port 52472 failed: Connection refused
*   Trying 127.0.0.1:80...
* Connected to localhost (127.0.0.1) port 80
> GET /api/hello HTTP/1.1
> Host: localhost
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 401 Unauthorized
< content-type: application/json
< vary: Accept-Encoding
< date: Wed, 06 Aug 2025 15:22:07 GMT
< server: envoy
< transfer-encoding: chunked
<
* Connection #0 to host localhost left intact
{
  "error":"Unauthorized"
}
```

</details>
<br />

The application correctly responds with the message "unauthorized" (combined with HTTP Status Code 401). Now presenting the (dummy) authorization header, the backend responds with data:

```shell
curl -v \
  -H "Authorization: my-jwt-token-here" \
  http://localhost/api/hello \
  | jq
```{{exec}}

<details>
<summary>example command output</summary>

```shell
* Host localhost:80 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:80...
* connect to ::1 port 80 from ::1 port 57088 failed: Connection refused
*   Trying 127.0.0.1:80...
* Connected to localhost (127.0.0.1) port 80
> GET /api/hello HTTP/1.1
> Host: localhost
> User-Agent: curl/8.5.0
> Accept: */*
> Authorization: my-jwt-token-here
>
< HTTP/1.1 200 OK
< vary: RSC, Next-Router-State-Tree, Next-Router-Prefetch
< content-type: application/json
< date: Wed, 06 Aug 2025 15:22:24 GMT
< server: envoy
< transfer-encoding: chunked
<
* Connection #0 to host localhost left intact
{
  "message":"Hello, World"
}
```

</details>
<br />

As seen previously, providing the (dummy) authorization header still allows access to the sensitive area.

But the same command previously granting access (bypassing Next.js middleware authentication) now fails because USP Core WAAP clears any headers not present in the configured list (where 'x-middleware-subrequest' is not present):

```shell
curl -v \
  -H "x-middleware-subrequest: middleware:middleware:middleware:middleware:middleware" \
  http://localhost/api/hello \
  | jq
```{{exec}}

<details>
<summary>example command output</summary>

```shell
* Host localhost:80 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:80...
* connect to ::1 port 80 from ::1 port 51314 failed: Connection refused
*   Trying 127.0.0.1:80...
* Connected to localhost (127.0.0.1) port 80
> GET /api/hello HTTP/1.1
> Host: localhost
> User-Agent: curl/8.5.0
> Accept: */*
> x-middleware-subrequest: middleware:middleware:middleware:middleware:middleware
>
< HTTP/1.1 401 Unauthorized
< content-type: application/json
< vary: Accept-Encoding
< date: Wed, 06 Aug 2025 15:20:51 GMT
< server: envoy
< transfer-encoding: chunked
<
* Connection #0 to host localhost left intact
{
  "error":"Unauthorized"
}
```

</details>
<br />

Voilà! This time, even still using an unpatched Next.js application backend, authorization bypass is not successful anymore.

> &#128270; Although acting as an example vulnerability here CVE-2025-29927 (Next.js middleware authentication bypass) marks the importance of having security measures in place. This particular vulnerability or similar ones are blocked by default without any specific configuration required by USP Core WAAP!

### Inspect USP Core WAAP logs

To get more details on why a request was blocked, you can look into the Core WAAP logs using:

```shell
kubectl logs \
  -n nextjs \
  -l app.kubernetes.io/name=usp-core-waap
```{{exec}}

Using the following command, you can filter for events of type 'removing request header' and, by parsing the log, see the details of the JSON payload:

```shell
kubectl logs \
  -n nextjs \
  -l app.kubernetes.io/name=usp-core-waap \
  | grep 'removing request header' \
  | sed -e 's/\[.*\] script log: {/{/' \
  | jq
```{{exec}}

This command selects the Core WAAP Pod via label `app.kubernetes.io/name=usp-core-waap` in the respective namespace.

That's it! You have successfully prevented an authentication bypass by using the USP Core WAAP.
