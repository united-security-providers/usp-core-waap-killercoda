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

<details>
<summary>example command output</summary>

```json
{
  "@timestamp": "2024-11-15T07:52:21.149Z",
  "request.id": "216dfcd7-0668-4e2a-b25d-edf911dfe3e5",
  "request.protocol": "HTTP/1.1",
  "request.method": "GET",
  "request.path": "/profile",
  "request.total_duration": "198",
  "request.body_bytes_received": "0",
  "response.status": "500",
  "response.details": "",
  "response.flags": "-",
  "response.body_bytes_sent": "407",
  "envoy.upstream.duration": "-",
  "envoy.upstream.host": "10.110.238.103:8080",
  "envoy.upstream.route": "-",
  "envoy.upstream.cluster": "core.waap.cluster.backend-juiceshop-8080-h1",
  "envoy.upstream.bytes_sent": "1034",
  "envoy.upstream.bytes_received": "401",
  "envoy.connection.id": "57",
  "client.address": "127.0.0.1:57716",
  "client.local_address": "127.0.0.1:8080",
  "client.direct_address": "127.0.0.1:57716",
  "host.hostname": "juiceshop-usp-core-waap-747b9748db-prq9r",
  "http.req_headers.referer": "-",
  "http.req_headers.useragent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0",
  "http.req_headers.authority": "juiceshop",
  "http.req_headers.forwarded_for": "-",
  "http.req_headers.forwarded_proto": "https"
}
```

</details>
<br />

Having the `request.id` at hand is very helpful for a user creating a support request enabling a USP Core WAAP administrator to filter out the requests matching the mentioned request and to examine the original backend error.

That's it! As you see providing custom error pages is a powerful feature to hide specific http backend errors or streamline the error page layout across multiple backends!
