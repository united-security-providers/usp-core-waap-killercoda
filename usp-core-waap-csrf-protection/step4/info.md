<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Attempt a CSRF attack using the "evil" website again
* See that this time the attack is blocked
* Verify that the "Username" value is still unchanged

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

### Access attacker website page

Open the [Attacker Website]({{TRAFFIC_HOST1_30070}}/waap.html) again.

### Hack "Username"

*Click the "Hack Username" button* - this will send the "evil" request to the OWASP Juice Shop and change the "Username".
This time, you will receive an error response from Core WAAP with the message "Invalid origin".

* In the "OWASP Juice Shop" browser tab, go to the "profile" page (or reload it) to verify that
  the "Username" was not changed this time, and is still "DemoUser" (or whatever value you set it to).

### Inspect USP Core WAAP logs

Let's have a look at the logs!

```shell
kubectl logs \
  --tail=-1 \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  | grep '\[access\]' \
  | grep 'response.details="csrf_origin_mismatch"'
```{{exec}}

> &#10071; If the command does not return anything, you may need to wait a few seconds and try again.

<details>
<summary>example command output</summary>

```shell
[2026-10-29 10:12:10.130000][access] request.id="db505e55-96e0-4ce1-9a4d-a91ab9c2dd06" request.protocol="HTTP/1.1" request.method="POST" request.path="/profile" request.total_duration="11" request.body_bytes_received="0" request.headers.referer="https://c22a3438-490c-4df0-a14e-e993ad82b463-10-244-6-59-30070.spch.r.killercoda.com/" request.headers.forwarded_proto="https" request.headers.forwarded_host="-" request.headers.forwarded_for="-" request.headers.useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:134.0) Gecko/20100101 Firefox/134.0" response.status="403" response.details="csrf_origin_mismatch" response.flags="-" response.body_bytes_sent="14" upstream.connection_id="128" upstream.duration="-" upstream.host="-" upstream.route="-" upstream.cluster="core.waap.cluster.backend-juiceshop-8080-h1" upstream.bytes_sent="0" upstream.bytes_received="0" client.id="-" client.address="10.244.0.1:34380" client.local_address="10.244.0.12:8080" client.direct_address="10.244.0.1:34380" hostname="juiceshop-usp-core-waap-59b48cd95c-nrd47"
```

Note the "csrf_origin_mismatch" value in the `response.details` field (and the 403 response status code). It indicates
that the request was blocked due to the CSRF policy feature. The `request.headers.referer` field shows the request
originated from the attacker website (node-port 30070) and not from the OWASP Juice Shop (node-port 30090).

> &#128270; Access log lines are identified by the `[access]` component, see [Logs and Metrics](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/operation/logs-metrics/#access-logs) for a description of all fields.

</details>
<br />

That's it! As you see enabling the CSRF Policy is a simple yet powerful feature to protect vulnerable applications from
falling prey to CSRF attacks.
