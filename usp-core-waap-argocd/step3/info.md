<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Access the Juiceshop backend application
* Approve automatic rule exceptions proposed by Auto-Learning Tool

From the previous step here the information how to access ArgoCD / Gogs WebUIs:

* Link: [Gogs application]({{TRAFFIC_HOST1_30080}}/user/login?redirect_to=)
  * Username: `gituser`
  * Password: `gitpassword`
* Link: [ArgoCD application]({{TRAFFIC_HOST1_30081}})
  * Username: `admin`
  * Get initial Password using command below

```shell
argocd admin initial-password -n argocd
```{{exec}}

### Access the Juiceshop backend application

### Approve automatic rule exceptions proposed by Auto-Learning Tool
