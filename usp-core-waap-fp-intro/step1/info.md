<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will access the OWASP Juice Shop demo application

### Access Juice Shop

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see an `HTTP 502 Bad Gateway` error)!

The OWASP Juice Shop demo web application has been setup behind USP Core WAAP (reachable via node-port 30090) and will be used. Go ahead and [access the shop]({{TRAFFIC_HOST1_30090}}) (**click to open in new browser tab**) generating some access logs.

> &#10071; Make sure to [access the Juice Shop]({{TRAFFIC_HOST1_30090}}) otherwise the validation in this step will fail...

In the next step we will have a closer look at logs / actions taken by **USP Core WAAP**. After accessing the shop and generating some traffic, press `CHECK`{{}} to continue.
