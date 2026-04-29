<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Access the OWASP Juiceshop backend application
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

### Access the OWASP Juiceshop backend application

Next access the [OWASP Juiceshop]({{TRAFFIC_HOST1_30085}}) and click around in the application and come back here once done (leave the new browser tab open).


### Approve automatic rule exceptions proposed by Auto-Learning Tool

In the background a process is checking for rule exceptions not already known and will add them to the code repository **in branch autolearn-tool** every 30s. You can see / confirm a proposed config change by the Auto-Learning Tool within [Gogs webUI]({{TRAFFIC_HOST1_30080}}/gituser/testrepo/compare/main...autolearn-tool) and after reviewing pull in these changes.

As previously seen head over to the [ArgoCD application]({{TRAFFIC_HOST1_30081}}) and watch changes being applied.

Feel free to repeat that process by probably generating more rule exceptions (i.e. try to login using username `' or true;` and any password)

> &#10071; While this demo is focused on automating configuration changes in a Core WAAP application setup, **never apply changes without review as you might decrease your security level** here showed only for demonstration purposes!
