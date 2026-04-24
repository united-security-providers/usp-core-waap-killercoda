<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Access Gogs webUI
* Access Argo CD webUI

### Access Gogs webUI

In this scenario the [Gogs](https://gogs.io/) application has been setup and will be used as a local code repository managing the actual applications to be deployed.

Access the application using the following information:

* Link: [Gogs application]({{TRAFFIC_HOST1_30080}})
* Username: `gituser`
* Password: `gitpassword`

### Access Argo CD webUI

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see an `HTTP 502 Bad Gateway` error)!

In this scenario the [Argo CD](https://argo-cd.readthedocs.io/) application has been setup and will be used to deploy and maintain application in a Kubernetes cluster.

Access the application using the following information:

* WebUI: [Argo CD application]({{TRAFFIC_HOST1_30081}})
* Username: admin
* Get initial Password using command below

```shell
argocd admin initial-password -n argocd
```{{exec}}

<details>
<summary>example command output</summary>

```shell

```

</details>
<br />

> &#10071; Verify that you can login to the [Argo CD]({{TRAFFIC_HOST1_30081}}) and [Gogs]({{TRAFFIC_HOST1_30080}}) webUI!
