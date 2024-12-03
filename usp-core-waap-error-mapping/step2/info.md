&#127919; In this step you will:

* Configure your CoreWaapService instance
* Again access the profile page
* Inspect USP Core WAAP logs

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

Next, you will setup an instace of Core WAAP using the created ConfigMap using:

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

(for this demo scenario the OWASP Core Rule Set has been disabled to focus on error pages and static file configuration)

Using this updated configuration the HTTP Error Codes 500 - 599 are now mapped to the configured error page.

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

Now re-check if a Core WAAP instance is active in the `backend` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAMESPACE   NAME                       AGE
backend     juiceshop-usp-core-waap    59s
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
backend     juiceshop-usp-core-waap-7849dbf5fd-4jt8c   1/1     Running   0          43s
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
  -l app.kubernetes.io/name=usp-core-waap \
  -n juiceshop \
  --for='condition=Ready'
```{{exec}}

</details>
<br />

### Again access the profile page

Try again to access the [profile page]({{TRAFFIC_HOST1_80}}/profile). The improper errorhandling should now be hidden as you access the backend via the configure USP Core WAAP instance now (if not, consider to look at the solution below).

> &#128270; The port forwarding was changed accordingly that the **traffic** to the [OWASP Juice Shop]({{TRAFFIC_HOST1_80}}) is now **routed via USP Core WAAP**.

Did you notice the different error page?
Not only are sensitive application information hidden but also the style can be changed to match the Juice Shop layout.

> &#10071; Make sure to have accessed the profile page (while not being logged in) otherwise the validation in this step will fail...

### Inspect USP Core WAAP logs

Let's have a look at the logs!

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  | grep '^{' | jq
```{{exec}}

<details>
<summary>example command output</summary>

```json
{
  "@timestamp": "2024-11-15T07:52:21.149Z",
  "request.id": "216dfcd7-0668-4e2a-b25d-edf911dfe3e5",
  "request.protocol": "HTTP/1.1",
  "request.method": "GET",
  "request.path": "/profile",
  "request.total_duration": "198",
  "request.body_bytes_received": "0",
  "response.status": "500",
  "response.details": "",
  "response.flags": "-",
  "response.body_bytes_sent": "407",
  "envoy.upstream.duration": "-",
  "envoy.upstream.host": "10.110.238.103:8080",
  "envoy.upstream.route": "-",
  "envoy.upstream.cluster": "core.waap.cluster.backend-juiceshop-8080-h1",
  "envoy.upstream.bytes_sent": "1034",
  "envoy.upstream.bytes_received": "401",
  "envoy.connection.id": "57",
  "client.address": "127.0.0.1:57716",
  "client.local_address": "127.0.0.1:8080",
  "client.direct_address": "127.0.0.1:57716",
  "host.hostname": "juiceshop-usp-core-waap-747b9748db-prq9r",
  "http.req_headers.referer": "-",
  "http.req_headers.useragent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0",
  "http.req_headers.authority": "juiceshop",
  "http.req_headers.forwarded_for": "-",
  "http.req_headers.forwarded_proto": "https"
}
```

</details>
<br />

Having the `request.id` at hand is very helpful for a user creating a support request enabling a USP Core WAAP administrator to filter out the requests matching the mentioned request and to examine the original backend error.

That's it! As you see providing custom error pages is a powerful feature to hide specific http backend errors or streamline the error page layout across multiple backends!
