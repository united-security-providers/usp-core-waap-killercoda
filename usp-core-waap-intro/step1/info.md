<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will login as Juice Shop admin

### Login as Juice Shop admin

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see an `HTTP 502 Bad Gateway` error)!

Once the scenario is ready click the following link to open the **unprotected Juice Shop web application** in your browser:

[Open Juice Shop]({{TRAFFIC_HOST1_8080}}/#/login)

Then execute an SQL-injection by logging in with username/password shown below:

* email `' OR true;` and
* password `fail` (or anything else except empty)

At last confirm that you succeeded by pressing `CHECK`{{}}
