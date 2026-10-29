<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Configure your CoreWaapService instance
* Again access the profile page
* Log in to the vulnerable "OWASP Juice Shop" application again
* Set a username in the profile page again

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`


### Configure your CoreWaapService instance

> &#128270; If you are inexperienced with kubernetes scroll down to the solution section where you'll find a step-by-step guide.

Next, you will setup an instance of Core WAAP with CSRF protection enabled using:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
  namespace: juiceshop
spec:
  websocket: true
  coraza:
    crs:
      defaultEnabled: false
  csrfPolicy:
    enabled: true
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

(for this demo scenario the OWASP Core Rule Set has been disabled to focus on the CSRF policy)

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

Create the Core WAAP instance using:

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

### Log in to the OWASP Juice Shop again

Try again to access the [OWASP Juice Shop]({{TRAFFIC_HOST1_30090}}/#/login) (**click to open in new browser tab**) and log in once
again with the same credentials as before:

* Username: `user@acme.com`
* Password: `123456`

### Again access the profile page

Try again to access the [profile page]({{TRAFFIC_HOST1_30090}}/profile).

> &#128270; The **traffic** to the [OWASP Juice Shop]({{TRAFFIC_HOST1_30090}}) is now **routed via USP Core WAAP** (using node-port 30090 instead of 30080).

> &#10071; Verify you are using the new browser window where the URL looks like "...-30090.spch.r.killercoda.com" (using Core WAAP) and not "...-30080.spch.r.killercoda.com"!

* Set a username like "DemoUser" again and save it.

Now you are ready to attempt a CSRF attack again in the next step.

> &#10071; Make sure to have accessed the profile page and set a username again.
