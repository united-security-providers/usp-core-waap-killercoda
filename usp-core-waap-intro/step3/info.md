<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your `CoreWaapService` instance to protect the Juice Shop
* Access the Juice Shop via USP Core WAAP
* Inspect the actions taken by USP Core WAAP

### Configure your CoreWaapService instance to protect the Juice Shop

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide

Having the USP Core WAAP operator installed and ready to go, you can configure the `CoreWaapService` instance to protect the Juice Shop web app:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
  namespace: juiceshop
spec:
  websocket: true
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: juiceshop
        port: 8080
        protocol:
          selection: h1
```{{copy}}

You can now re-check if a USP Core WAAP instance is active in the `juiceshop` namespace:

```shell
kubectl get corewaapservices --all-namespaces
```{{exec}}

In addition check if a USP Core WAAP pod is running:

```shell
kubectl get pods \
  -l app.kubernetes.io/name=usp-core-waap \
  --all-namespaces
```{{exec}}

> &#8987; Wait until the USP Core WAAP pod is running before trying to access the application in the next step (otherwise you'll get a HTTP 502 response)!

<details>
<summary>hint</summary>

There is a file in your home directory with an example `CoreWaapService` definition ready to be applied using `kubectl apply -f` ...

</details>
<br />

<details>
<summary>solution</summary>

First create the USP Core WAAP instance using

```shell
kubectl apply -f juiceshop-core-waap.yaml
```{{exec}}

Then wait for its readiness using

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap \
  -n juiceshop \
  --for='condition=Ready'
```{{exec}}

And finally inspect the USP Core WAAP instance logs using

```shell
kubectl logs -f \
  -l app.kubernetes.io/name=usp-core-waap \
  -n juiceshop \
  |grep APPLICATION-ATTACK-SQLI
```{{exec}}

</details>
<br />

### Access the Juice Shop via USP Core WAAP

> &#128270; The port forwarding was changed accordingly that the traffic to the Juice Shop web application is now routed **via USP Core WAAP**.

Try if you still can [exploit the vulnerability]({{TRAFFIC_HOST1_80}}/#/login) in the login dialog using the previous SQL-injection (remember email `' OR true;` and any password except empty)...

The described exploit is now blocked by the USP Core WAAP. If you open the browser developer tools (hit `F12` on most common browsers), you can see that the login request is answered with the `response status 403`.

> &#128270; Note there are other rejections blocked by the default USP Core WAAP configuration seen in the browser developer tools like `socket.io` outbound connections thus you might want to filter your query using the `login` keyword.

### Inspect the actions taken by USP Core WAAP

To see the actual block you can filter the USP Core WAAP Pod logs for 'APPLICATION-ATTACK-SQLI' (refer to the [OWASP Core Rule Set documentation](https://coreruleset.org/docs/rules/rules/) while you are trying to login using the mentioned SQL-injection

```shell
kubectl logs -f \
  -l app.kubernetes.io/name=usp-core-waap \
  -n juiceshop \
  |grep APPLICATION-ATTACK-SQLI
```{{exec}}

> &#128270; While fixing vulnerabilities / writing secure application code is imminent, USP Core WAAP can help you out taking the time it takes to fix all vulnerabilities and giving you an additional layer of security!

That's it! You just protected the vulnerable Juice Shop backend application using USP Core WAAP.
