&#127919; In this step you will:

* Attempt a CSRF attack using the "evil" website again
* See that this time the attack is blocked
* Verify that the "Username" value is still unchanged

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***`

### STEP 4 - Access attacker website page

Open the [Attacker Website]({{TRAFFIC_HOST1_9090}}) again. This time you will need to press the
second button to send a forged request, because the application is no longer accessible over port
8080, as we have now routed all traffic over Core-WAAP on port 80.

### Hack "Username"

*Click the second "Hack Username" button* - this will send the "evil" request to the Juiceshop and change the "Username". 
You will receive an error response from Core WAAP with the message "unknown origin". 


### Inspect USP Core WAAP logs

Let's have a look at the logs!

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  | grep '^{' | jq
```{{exec}}

> &#10071; If the command does not return anything, you may need to wait a few seconds and try again.

<details>
<summary>example command output</summary>

```json
{
  "@timestamp": "2025-01-28T10:12:10.130Z",
  "request.id": "db505e55-96e0-4ce1-9a4d-a91ab9c2dd06",
  "request.protocol": "HTTP/1.1",
  "request.method": "POST",
  "request.path": "/profile",
  "request.total_duration": "11",
  "request.body_bytes_received": "0",
  "response.status": "403",
  "response.details": "csrf_origin_mismatch",
  "response.flags": "-",
  "response.body_bytes_sent": "14",
  "envoy.upstream.duration": "-",
  "envoy.upstream.host": "-",
  "envoy.upstream.route": "-",
  "envoy.upstream.cluster": "core.waap.cluster.backend-juiceshop-8080-h1",
  "envoy.upstream.bytes_sent": "0",
  "envoy.upstream.bytes_received": "0",
  "envoy.connection.id": "128",
  "client.address": "127.0.0.1:34380",
  "client.local_address": "127.0.0.1:8080",
  "client.direct_address": "127.0.0.1:34380",
  "host.hostname": "juiceshop-usp-core-waap-59b48cd95c-nrd47",
  "http.req_headers.referer": "https://c22a3438-490c-4df0-a14e-e993ad82b463-10-244-6-59-9090.spch.r.killercoda.com/",
  "http.req_headers.useragent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:134.0) Gecko/20100101 Firefox/134.0",
  "http.req_headers.authority": "c22a3438-490c-4df0-a14e-e993ad82b463-10-244-6-59-80.spch.r.killercoda.com",
  "http.req_headers.forwarded_for": "-",
  "http.req_headers.forwarded_proto": "https"
}
```

Note the "csrf_origin_mismatch" value in the "response.details" field (and the 403 response status code). It indicates
that the request was blocked due to the CSRF policy feature.

</details>
<br />

That's it! As you see enabling the CSRF Policy is a simple yet powerful feature to prevent vulnerable applications to 
fall prey to CSRF attacks.
