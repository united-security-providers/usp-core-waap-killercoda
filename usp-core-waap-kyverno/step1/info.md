<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Verify Kyverno setup
* Inspect the initial Kyverno policy

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`!

### Verify Kyverno setup

The [Kyverno](https://kyverno.io/) application is used as a policy enforcement engine and has been pre-installed into Kubernetes namespace `kyverno`. Now let's verify kyverno is ready to use!

We want to list

```shell
kubectl get pods -n kyverno
```{{exec}}

> &#10071; Verify that all PODs are running otherwise policy enforcement will not be possible!

<details>
<summary>example command output</summary>

```shell
NAME                                            READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-c67dcfdc7-24gps    1/1     Running   0          5m54s
kyverno-background-controller-5bdcfccf7-5ngbb   1/1     Running   0          5m54s
kyverno-cleanup-controller-c9c5b58bd-xbbj7      1/1     Running   0          5m54s
kyverno-reports-controller-8d888f4bf-cvwwr      1/1     Running   0          5m54s
```

</details>

### Inspect the initial Kyverno policy

An initial Kyverno `ValidatingPolicy` has been installed to the cluster requiring every Core WAAP instance to use `spec.coraza.crs.paranoiaLevel` value of `2` or higher. Let's have a look at this policy by first listing all installed validating policies in the cluster:

```shell
kubectl get validatingpolicy
```{{exec}}

<details>
<summary>example command output</summary>

```shell
NAME                          AGE     READY
check-coraza-paranoia-level   2m32s   true
```

</details>

Next we want to inspect the policy and see the full content which we achieve by querying the policy resource and show it as YAML encoded version:

```shell
kubectl get validatingpolicy/check-coraza-paranoia-level -o yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
apiVersion: policies.kyverno.io/v1
kind: ValidatingPolicy
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"policies.kyverno.io/v1","kind":"ValidatingPolicy","metadata":{"annotations":{"policies.kyverno.io/description":"Ensures that CoreWaapService resources are only applied if the Coraza paranoia level is set to at least 2.","policies.kyverno.io/title":"Require Paranoia Level 2 or Higher"},"name":"check-coraza-paranoia-level"},"spec":{"matchConstraints":{"resourceRules":[{"apiGroups":["waap.core.u-s-p.ch"],"apiVersions":["*"],"operations":["CREATE","UPDATE"],"resources":["corewaapservices"]}]},"validationActions":["Deny"],"validations":[{"expression":"has(object.spec.coraza) \u0026\u0026 has(object.spec.coraza.crs) \u0026\u0026 has(object.spec.coraza.crs.paranoiaLevel) \u0026\u0026 object.spec.coraza.crs.paranoiaLevel \u003e= 2","message":"The paranoia level (spec.coraza.crs.paranoiaLevel) must be 2 or higher."}]}}
    policies.kyverno.io/description: Ensures that CoreWaapService resources are only
      applied if the Coraza paranoia level is set to at least 2.
    policies.kyverno.io/title: Require Paranoia Level 2 or Higher
  creationTimestamp: "2026-10-21T13:29:57Z"
  generation: 1
  name: check-coraza-paranoia-level
  resourceVersion: "998"
  uid: d6d6d8c4-5dea-4a82-9432-e366127f64e8
spec:
  matchConstraints:
    resourceRules:
    - apiGroups:
      - waap.core.u-s-p.ch
      apiVersions:
      - '*'
      operations:
      - CREATE
      - UPDATE
      resources:
      - corewaapservices
  validationActions:
  - Deny
  validations:
  - expression: has(object.spec.coraza) && has(object.spec.coraza.crs) && has(object.spec.coraza.crs.paranoiaLevel)
      && object.spec.coraza.crs.paranoiaLevel >= 2
    message: The paranoia level (spec.coraza.crs.paranoiaLevel) must be 2 or higher.
status:
  autogen: {}
  conditionStatus:
    conditions:
    - lastTransitionTime: "2026-10-21T13:29:57Z"
      message: Webhook configured.
      reason: Succeeded
      status: "True"
      type: WebhookConfigured
    - lastTransitionTime: "2026-10-21T13:29:57Z"
      message: Policy is ready for reporting.
      reason: Succeeded
      status: "True"
      type: RBACPermissionsGranted
    message: ""
    ready: true
  generated: false
```

</details>

> &#128270; More information on how Kyverno validating policies are structured can be found at the [ValidatingPolicy documentation](https://kyverno.io/docs/policy-types/validating-policy/) on the [kyverno.io](https://kyverno.io) website.

The important sections of the policy are `matchConstraints` which applies this policy to `CREATE` and `UPDATE` operations on Kubernetes resources of kind `CoreWaapService` (resource `corewaapservices`), and `validations` which defines a [CEL](https://kubernetes.io/docs/reference/using-api/cel/) expression that must evaluate to `true` for the resource to be admitted. With `validationActions: [Deny]` any violating request is rejected.

In the next step we will create Core WAAP configurations and see policy enforcement in action.
