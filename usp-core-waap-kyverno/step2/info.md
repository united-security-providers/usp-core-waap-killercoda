<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Create a Core WAAP resource passing the policy
* Create a Core WAAP resource failing the policy

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`!

### Create a Core WAAP resource passing the policy

Now let's create a Core WAAP resource to protect the OWASP Juiceshop backend installed in the cluster by applying the following resource configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
  namespace: juiceshop
spec:
  coraza:
    crs:
      paranoiaLevel: 2
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

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/juiceshop-usp-core-waap created
```

</details>

Since this Core WAAP instance configures `paranoiaLevel:2` we expect no complications...

<details>
<summary>hint</summary>

Use `kubectl apply -f -` on the command-line on the right-hand side and paste the resource configuration ...

</details>
<details>
<summary>solution</summary>

```shell
cat << EOF | kubectl apply -f -
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
  namespace: juiceshop
spec:
  coraza:
    crs:
      paranoiaLevel: 2
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: juiceshop
        port: 8080
        protocol:
          selection: h1
EOF
```{{exec}}

Then wait for its readiness using

```shell
kubectl wait pods \
  -l app.kubernetes.io/name=usp-core-waap-proxy\
  -n juiceshop \
  --for='condition=Ready'
```{{exec}}

</details>

### Create a Core WAAP resource failing the policy

Now let's create a Core WAAP resource to protect the `HTTPbin` backend installed in the cluster by applying the following resource configuration:

```yaml
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: httpbin-usp-core-waap
  namespace: httpbin
spec:
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: httpbin
        port: 8081
        protocol:
          selection: h1
```{{copy}}

<details>
<summary>example command output</summary>

```shell
Error from server: error when creating "STDIN": admission webhook "vpol.validate.kyverno.svc-fail" denied the request: Policy check-coraza-paranoia-level failed: The paranoia level (spec.coraza.crs.paranoiaLevel) must be 2 or higher.
```

</details>

Since this Core WAAP instance does not configure `paranoiaLevel` (using the default value of 1) the Kyverno policy blocks creation of this resource...

<details>
<summary>hint</summary>

Use `kubectl apply -f -` on the command-line on the right-hand side and paste the resource configuration ...

</details>
<details>
<summary>solution</summary>

```shell
cat << EOF | kubectl apply -f -
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: httpbin-usp-core-waap
  namespace: httpbin
spec:
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: httpbin
        port: 8081
        protocol:
          selection: h1
EOF
```{{exec}}
</details>

Resource creation will fail because the default `spec.coraza.crs.paranoiaLevel` is 1 (see [documentation](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespeccorazacrs))

If you want to create another Core WAAP instance you need to set at least paranoiaLevel 2 like

```shell
cat << EOF | kubectl apply -f -
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: httpbin-usp-core-waap
  namespace: httpbin
spec:
  coraza:
    crs:
      paranoiaLevel: 3
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: httpbin
        port: 8081
        protocol:
          selection: h1
EOF
```{{exec}}

This is a very basic example of how a Kubernetes Infrastructure Administrator (or Team) can limit resource creations and using this technique security base-line settings can be enforced across multiple USP Core WAAP instances.
