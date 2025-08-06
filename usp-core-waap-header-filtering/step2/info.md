<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your CoreWaapService instance
* Again access the vulnerable Next.js demo application
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

Applying USP Core WAAP provides immediate protection against CVE-2025-29927 without requiring downtime or changes to the application's source code. It's a cost-effective solution that reduces the risk of attacks until a permanent patch on the application source code can be implemented. In this particular example the use of USP Core WAAP in its default configuration prevents exploitation of CVE-2025-29927!

**While the use of a USP Core WAAP serves as a quick and generic solution to mitigate a vulnerability until an application update can be applied this is no replacement to patch application code!**

### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Having the USP Core WAAP operator installed and ready to go, you can configure the USP Core WAAP `instance` by applying the following `CoreWaapService` resource configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: nextjs-app-core-waap
  namespace: nextjs
spec:
  routes:
    - match:
        path: /
        pathType: PREFIX
      backend:
        address: nextjs-app
        port: 3000
        protocol:
          selection: h1
```{{copy}}

This is uses the default security configuration which includes header filtering (for both request and responses) preconfigured by the STANDARD list of headers (see [documentation](https://docs.united-security-providers.ch/usp-core-waap/crd-doc/#corewaapservicespecheaderfilteringrequest)). Not this feature allows to switch to other pre-defined sets of request/reaponse Headers and additionally a custom list of headers.

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/nextjs-app-core-waap created
```

</details>
<br />

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

Now re-check if a Core WAAP instance is active in the `nextjs` namespace:

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
nextjs      nextjs-app-usp-core-waap-7849dbf5fd-4jt8c  1/1     Running   0          43s
```

</details>
<br />

> &#8987; Wait until the USP Core WAAP pod is running before trying to access the API in the next step (otherwise you'll get a HTTP 502 response)!

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

This time we will access the Next.js demo application via USP Core WAAP and re-evaluate the responses. The same backend application code is in use (you can check `kubectl get pods -n nextjs` and confirm POD runtime).


```shell
curl http://localhost:3000/api/hello
```{{exec}}

<details>
<summary>example command output</summary>

```shell
{"error":"Unauthorized"}
```

</details>

The application correctly responds with message "unauthorized" (combined with HTTP Status Code 401). Now presenting (a fake) authorization header the backend responds with data:

```shell
curl -H "Authorization: my-jwt-token-here" http://localhost/api/hello
```{{exec}}

<details>
<summary>example command output</summary>

```shell
{"message":"Hello, World"}
```

</details>

Still the request is denied (by the actual application backend), however the same next command previously granting access (bypassing Next.js middleware authentication) now fails, because USP Core WAAP clears any headers not present in the configured list:

```shell
curl -vH "x-middleware-subrequest: middleware:middleware:middleware:middleware:middleware" http://localhost:3000/api/hello
```

<details>
<summary>example command output</summary>

```shell
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> GET /api/hello HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> x-middleware-subrequest: middleware:middleware:middleware:middleware:middleware
>
< HTTP/1.1 403 Forbidden
< date: Wed, 06 Aug 2025 12:24:04 GMT
< server: envoy
< content-length: 0
<
* Connection #0 to host localhost left intact
```

</details>

Voilà! This time, even still using an unpatched Next.js application backend, authorization bypass is not successful anymore.

> &#128270; Although acting as an example vulnerability here CVE-2025-29927 (Next.js middleware authentication bypass) marks the importance of having security measures in place. This particular vulnerability (or similar ones) are blocked by default without any specific configuration required!

To get more details why a request was blocked you can look into the Core WAAP logs using:

```shell
kubectl logs \
  -n nextjs \
  -l app.kubernetes.io/name=usp-core-waap
```{{exec}}


Using the following command you can extract the JSON part filtering for our `/debug/pprof` request getting the details about actions taken by USP Core WAAP:

```shell
kubectl logs \
  -n nextjs \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=1000
```{{exec}}

This command selects the Core WAAP pod via label `app.kubernetes.io/name=usp-core-waap` in the respective namespace.

That's it! You have successfully prevented an authentication bypass by enabling the USP Core WAAP web application firewall.
