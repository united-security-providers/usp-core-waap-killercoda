<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your CoreWaapService instance
* Again access the profile page
* Inspect USP Core WAAP logs

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Having the USP Core WAAP operator installed and ready to go, you can now configure the USP Core WAAP `instance`.

At first you will configure the custom error page with static content using a kubernetes `ConfigMap`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-waap-static-resources
  namespace: juiceshop
data:
  error5xx.html: |
    <!DOCTYPE html>
    <html>
    <body style="background-color:#303030; font-family: Roboto, Helvetica Neue, sans-serif;">
      <div
        style="width: 60%%; position: absolute; top: 30%%; left: 20%%; background-color:#424242;color:white;padding:20px; text-align: center;">
        <h2>Error</h2>
        <p>Please retry to access the webpage. In case the request is not successful get in touch with support@...
          providing the information below.</p>
        <div style=" text-align:left; width: 40%%; margin: auto;" ;>
          <b>Backend status code:</b> %RESPONSE_CODE% <br>
          <b>Client request id:</b> %REQ(X-REQUEST-ID)% <br>
          <b>Timestamp:</b> %START_TIME%
        </div>
        <br>
        <img src="/assets/public/images/JuiceShop_Logo.png" width="150" height="180">
      </div>
    </body>
    </html>
```

There is an example ConfigMap prepared for you ready to be applied using:

```shell
kubectl apply -f error-configmap.yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
configmap/core-waap-static-resources created
```

</details>
<br />

Next, you will setup an instance of Core WAAP using the created ConfigMap using:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
  namespace: juiceshop
spec:
  webResources:
    configMap: core-waap-static-resources
    path: /resources/
    errorPages:
    - key: error5xx.html
      statusCode: 5xx
  websocket: true
  coraza:
    crs:
      mode: DISABLED
  routes:
    - match:
        path: /
        pathType: PREFIX
      backend:
        address: juiceshop
        port: 8080
        protocol:
          selection: h1
```{{copy}}

(for this demo scenario the OWASP Core Rule Set has been disabled to focus on custom error pages)

Using this updated configuration the HTTP Error Codes 500 - 599 are now mapped to the configured custom error page.

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/juiceshop-usp-core-waap created
```

</details>
<br />

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

Now re-check if a Core WAAP instance is active in the `juiceshop` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                       AGE
juiceshop   juiceshop-usp-core-waap    59s
```

</details>
<br />

Check if a Core WAAP Pod is running:

```shell
kubectl get pods \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --all-namespaces
```{{exec}}


<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                                       READY   STATUS    RESTARTS   AGE
juiceshop   juiceshop-usp-core-waap-7849dbf5fd-4jt8c   1/1     Running   0          43s
```

</details>
<br />

> &#8987; Wait until the USP Core WAAP pod is running before trying to access the API in the next step (otherwise you'll get a HTTP 502 response)!

<details>
<summary>solution</summary>

First create the configmap:

```shell
kubectl apply -f error-configmap.yaml
```{{exec}}

Next, create the Core WAAP instance using:

```shell
kubectl apply -f juiceshop-core-waap.yaml
```{{exec}}

and wait for its readiness:

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  -n juiceshop \
  --for='condition=Ready' \
  --timeout 300s
```{{exec}}

</details>
<br />

### Again access the profile page

Try again to access the [profile page]({{TRAFFIC_HOST1_30090}}/profile) (**click to open in new browser tab**). The improper error handling should now be hidden as you access the backend via the configured USP Core WAAP instance now (if not re-check configuration or consider looking at the solution below).

> &#128270; The **traffic** to the [OWASP Juice Shop]({{TRAFFIC_HOST1_30090}}) is now **routed via USP Core WAAP** (using node-port 30090 instead of 30080).

> &#10071; Verify you are using the new browser window where the URL looks like "...-30090.spch.r.killercoda.com" (using Core WAAP) and not "...-30080.spch.r.killercoda.com"!

Did you notice the different error page?
Not only are sensitive application information hidden but also the style can be changed to match the Juice Shop layout.

> &#10071; Make sure to have accessed the profile page (while not being logged in) otherwise the validation in this step will fail...

### Inspect USP Core WAAP logs

Let's have a look at the logs!

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[access\]' \
  | grep 'request.path="/profile"'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
[2026-10-28 14:52:21.149000][access] request.id="216dfcd7-0668-4e2a-b25d-edf911dfe3e5" request.protocol="HTTP/1.1" request.method="GET" request.path="/profile" request.total_duration="198" request.body_bytes_received="0" request.headers.referer="-" request.headers.forwarded_proto="https" request.headers.forwarded_host="-" request.headers.forwarded_for="-" request.headers.useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" response.status="500" response.details="via_upstream" response.flags="-" response.body_bytes_sent="407" upstream.connection_id="57" upstream.duration="190" upstream.host="10.110.238.103:8080" upstream.route="-" upstream.cluster="core.waap.cluster.backend-juiceshop-8080-h1" upstream.bytes_sent="1034" upstream.bytes_received="401" client.id="-" client.address="10.244.0.1:57716" client.local_address="10.244.0.12:8080" client.direct_address="10.244.0.1:57716" hostname="juiceshop-usp-core-waap-747b9748db-prq9r"
```

</details>
<br />

> &#128270; Access log lines are identified by the `[access]` component, see [Logs and Metrics](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/operation/logs-metrics/#access-logs) for a description of all fields.

Note the `response.status="500"` returned by the backend and the `request.id` matching the "Client request id" shown on the custom error page.

Having the `request.id` at hand is very helpful for a user creating a support request enabling a USP Core WAAP administrator to filter out the requests matching the mentioned request and to examine the original backend error.

That's it! As you see providing custom error pages is a powerful feature to hide specific http backend errors or streamline the error page layout across multiple backends!
