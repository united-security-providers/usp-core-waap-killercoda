<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will trigger an SQL-injection attempt

### Trigger an SQL-injection attempt

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

The [OWASP Juice Shop]({{TRAFFIC_HOST1_80}}) demo web application has been setup and will be used.

> &#128270; The attempt to make an SQL-injection will be not be successful (prevented by USP Core WAAP)

[Access the Juice Shop]({{TRAFFIC_HOST1_80}}/login) web application using your browser and try to execute an SQL-injection by logging in with:

* email `' OR true;` and
* password `fail` (or anything else except empty)

> &#128270; The block of this SQL-injection request is **NOT** a false positive because it is intended (so called true positive)!

In the next step we will have a closer look at logs / actions taken by **USP Core WAAP** in the next step. After accessing the shop and triggering the SQL-injection, press `CHECK`{{}} to continue.
