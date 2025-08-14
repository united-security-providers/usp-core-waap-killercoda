<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will login as Juice Shop admin

### Login as Juice Shop admin

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see an `HTTP 502 Bad Gateway` error)!

[Access the unprotected Juice Shop]({{TRAFFIC_HOST1_8080}}/#/login) web application using your browser and execute an SQL-injection by logging in with:

* email `' OR true;` and
* password `fail` (or anything else except empty)

Then verify if you succeeded by pressing `CHECK`{{}}
