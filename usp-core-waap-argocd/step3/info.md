<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Access the OWASP Juiceshop backend application
* Approve automatic rule exceptions proposed by Auto-Learning Tool

> &#128270; From the previous step access to [ArgoCD application]({{TRAFFIC_HOST1_30081}} using username `admin` (execute `argocd admin initial-password -n argocd` to get initial password) and [Gogs application]({{TRAFFIC_HOST1_30080}}/ using username `gituser` and password `gitpassword`

### Access the OWASP Juiceshop backend application

Next access the OWASP Juiceshop and click around in the application and come back here once done (leave the new browser tab open):

[Juiceshop application backend]({{TRAFFIC_HOST1_30085}}) (click to open a new tab)

### Approve automatic rule exceptions proposed by Auto-Learning Tool

In the background a process is checking for rule exceptions every 10s not already known and will add them to the code repository **in a branch named autolearn-tool**. You can see / confirm a proposed config change by the Auto-Learning Tool within [Gogs webUI]({{TRAFFIC_HOST1_30080}}/gituser/testrepo/compare/main...autolearn-tool) and after creating/reviewing the pull request changes will be applied by ArgoCD.

As previously seen head over to the [ArgoCD application]({{TRAFFIC_HOST1_30081}}) and watch changes being applied.

Feel free to repeat that process by probably generating more rule exceptions (i.e. try to login using username `' or true;` and any password)...

Again open up diff view in [Gogs webUI]({{TRAFFIC_HOST1_30080}}/gituser/testrepo/compare/main...autolearn-tool) (comparing `autolearn-tool` branch to `main`) to see new changes being proposed.

> &#10071; While this demo is focused on automating configuration changes in a Core WAAP application setup, **never apply changes without reviewing them as you might decrease your security level**! The indicated SQL-injection here being accepted would be a reduction in security level!
