&#127919; In this step you will:

* Inspect the USP Core WAAP logs
* Reconfigure the USP Core WAAP instance to eliminate (or mitigate) false positives
* Check the logs to verify false positives are gone

### Inspect the USP Core WAAP logs

Let's have a look at the logs!

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep "\[critical\]\[wasm\]" \
  | grep -E '"request.path":"[^"]*"'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
[2024-11-21 10:14:15.017][15][critical][wasm] [source/extensions/common/wasm/context.cc:1204] wasm log core.waap.listener.filters.http.httpFilter.wasm.coraza.config coraza-vm: {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PDEDm7q\u0026sid=Q_d8fQ7HSAYmjI_kAAAF","crs.violated_rule":{"id":920420,"category":"REQUEST-920-PROTOCOL-ENFORCEMENT","severity":"CRITICAL","data":"|text/plain|","message":"Request content type is not allowed by policy","matched_data":"REQUEST_HEADERS","matched_data_name":"content-type","tags":["application-multi","language-multi","platform-multi","attack-protocol","paranoia-level/1","OWASP_CRS","capec/1000/255/153","PCI/12.1"]},"client.address":"127.0.0.1","transaction.id":"xpIaKdMfdmgZPBdBZWM","crs.version":"OWASP_CRS/4.3.0","request.id":"ce104af8-283d-4c8b-a3bf-609692267f57"}
[2024-11-21 10:14:15.026][15][critical][wasm] [source/extensions/common/wasm/context.cc:1204] wasm log core.waap.listener.filters.http.httpFilter.wasm.coraza.config coraza-vm: {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PDEDm7q\u0026sid=Q_d8fQ7HSAYmjI_kAAAF","crs.violated_rule":{"id":949111,"category":"REQUEST-949-BLOCKING-EVALUATION","severity":"EMERGENCY","data":"","message":"Inbound Anomaly Score Exceeded in phase 1 (Total Score: 5)","matched_data":"TX","matched_data_name":"blocking_inbound_anomaly_score","tags":["anomaly-evaluation","OWASP_CRS"]},"client.address":"127.0.0.1","transaction.id":"xpIaKdMfdmgZPBdBZWM","crs.version":"OWASP_CRS/4.3.0","request.id":"ce104af8-283d-4c8b-a3bf-609692267f57"}
[2024-11-21 10:14:15.401][15][critical][wasm] [source/extensions/common/wasm/context.cc:1204] wasm log core.waap.listener.filters.http.httpFilter.wasm.coraza.config coraza-vm: {"request.path":"/rest/user/login","crs.violated_rule":{"id":942100,"category":"REQUEST-942-APPLICATION-ATTACK-SQLI","severity":"CRITICAL","data":"Matched Data: s\u00261; found within ARGS_POST:json.email: ' OR true;","message":"SQL Injection Attack Detected via libinjection","matched_data":"ARGS_POST","matched_data_name":"json.email","tags":["application-multi","language-multi","platform-multi","attack-sqli","paranoia-level/1","OWASP_CRS","capec/1000/152/248/66","PCI/6.5.2"]},"client.address":"127.0.0.1","transaction.id":"HIkttRpzYXYhzkhUyMl","crs.version":"OWASP_CRS/4.3.0","request.id":""}
[2024-11-21 10:14:15.405][15][critical][wasm] [source/extensions/common/wasm/context.cc:1204] wasm log core.waap.listener.filters.http.httpFilter.wasm.coraza.config coraza-vm: {"request.path":"/rest/user/login","crs.violated_rule":{"id":949110,"category":"REQUEST-949-BLOCKING-EVALUATION","severity":"EMERGENCY","data":"","message":"Inbound Anomaly Score Exceeded (Total Score: 5)","matched_data":"TX","matched_data_name":"blocking_inbound_anomaly_score","tags":["anomaly-evaluation","OWASP_CRS"]},"client.address":"127.0.0.1","transaction.id":"HIkttRpzYXYhzkhUyMl","crs.version":"OWASP_CRS/4.3.0","request.id":""}
[2024-11-21 10:14:15.485][15][critical][wasm] [source/extensions/common/wasm/context.cc:1204] wasm log core.waap.listener.filters.http.httpFilter.wasm.coraza.config coraza-vm: {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PDEDnrH\u0026sid=sK5_0cUWUSrqisfuAAAG","crs.violated_rule":{"id":920420,"category":"REQUEST-920-PROTOCOL-ENFORCEMENT","severity":"CRITICAL","data":"|text/plain|","message":"Request content type is not allowed by policy","matched_data":"REQUEST_HEADERS","matched_data_name":"content-type","tags":["application-multi","language-multi","platform-multi","attack-protocol","paranoia-level/1","OWASP_CRS","capec/1000/255/153","PCI/12.1"]},"client.address":"127.0.0.1","transaction.id":"yxVTJkWNRxjzsFWuXDV","crs.version":"OWASP_CRS/4.3.0","request.id":"98381a37-fb77-4b0a-9a7a-e527db186ccc"}
[2024-11-21 10:14:15.503][15][critical][wasm] [source/extensions/common/wasm/context.cc:1204] wasm log core.waap.listener.filters.http.httpFilter.wasm.coraza.config coraza-vm: {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PDEDnrH\u0026sid=sK5_0cUWUSrqisfuAAAG","crs.violated_rule":{"id":949111,"category":"REQUEST-949-BLOCKING-EVALUATION","severity":"EMERGENCY","data":"","message":"Inbound Anomaly Score Exceeded in phase 1 (Total Score: 5)","matched_data":"TX","matched_data_name":"blocking_inbound_anomaly_score","tags":["anomaly-evaluation","OWASP_CRS"]},"client.address":"127.0.0.1","transaction.id":"yxVTJkWNRxjzsFWuXDV","crs.version":"OWASP_CRS/4.3.0","request.id":"98381a37-fb77-4b0a-9a7a-e527db186ccc"}
```

</details>
<br />

Notice the high amount of `"request.path":"/socket.io/?...` requests being blocked?

The log message is split into two parts: First part prior to `coraza-vm:` containing the generic envoy log information indicating what module is taking action, which in our use-case is the [coraza web application firewall](https://github.com/corazawaf/coraza) module and the second part which is the actual payload log formatted as JSON.

Using the following command you can parse the JSON output and hereby as a human have better insight into the actual action:

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep "coraza-vm.*/socket.io" \
  | sed -e 's/.* coraza-vm: //' \
  | jq
```{{exec}}

<details>
<summary>example command output</summary>

```json
{
  "request.path": "/socket.io/?EIO=4&transport=polling&t=PDEjrVo&sid=HqpIjqKPyn_lf7d4AAN0",
  "crs.violated_rule": {
    "id": 920420,
    "category": "REQUEST-920-PROTOCOL-ENFORCEMENT",
    "severity": "CRITICAL",
    "data": "|text/plain|",
    "message": "Request content type is not allowed by policy",
    "matched_data": "REQUEST_HEADERS",
    "matched_data_name": "content-type",
    "tags": [
      "application-multi",
      "language-multi",
      "platform-multi",
      "attack-protocol",
      "paranoia-level/1",
      "OWASP_CRS",
      "capec/1000/255/153",
      "PCI/12.1"
    ]
  },
  "client.address": "172.18.0.1",
  "transaction.id": "ZelukCRiZUGvQRXwTIC",
  "crs.version": "OWASP_CRS/4.3.0",
  "request.id": "e58553ec-d1cc-476d-b48b-f38d8393835d"
}
{
  "request.path": "/socket.io/?EIO=4&transport=polling&t=PDEjrVo&sid=HqpIjqKPyn_lf7d4AAN0",
  "crs.violated_rule": {
    "id": 949111,
    "category": "REQUEST-949-BLOCKING-EVALUATION",
    "severity": "EMERGENCY",
    "data": "",
    "message": "Inbound Anomaly Score Exceeded in phase 1 (Total Score: 5)",
    "matched_data": "TX",
    "matched_data_name": "blocking_inbound_anomaly_score",
    "tags": [
      "anomaly-evaluation",
      "OWASP_CRS"
    ]
  },
  "client.address": "172.18.0.1",
  "transaction.id": "ZelukCRiZUGvQRXwTIC",
  "crs.version": "OWASP_CRS/4.3.0",
  "request.id": "e58553ec-d1cc-476d-b48b-f38d8393835d"
}
```

</details>

> &#128270; Look out for the `crs.violated_rule` field which contains the Core Rule Set rule number triggering the action.

The field `crs.violated_rule` indicates what Core Rule Set Rule has triggered. The `Rule ID 920420` blocks this request because the content-type is `text/plain` which is untrusted.

> &#128270; The Rule IDs in the 949... range are the blocking condition rules and are not of interest. In our case the **Rule ID 920420** (Protocol enforcement) is.

### Reconfigure the USP Core WAAP instance to eliminate (or mitigate) false positives

You want these `/socket.io` requests to succeed (in this use-case the block of these requests is a `false positive`) and therefore you add an exception rule to the core-waap `CRS` configuration using `requestRuleExceptions`:

```yaml
...
spec:
  crs:
    requestRuleExceptions:
    - ruleId: 920420
      requestPartType: "REQUEST_HEADERS"
      requestPartName: "content-type"
      regEx: true
      location: "socket.io/*"
      metadata:
        comment: "Enable socket.io requests"
        date: "2024-11-21"
        createdBy: killercoda-user
...
```

Apply the updated `CoreWaapService` instance configuration prepared for you using:

```shell
kubectl apply -f juiceshop-core-waap.yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/juiceshop-usp-core-waap configured
```

</details>

> &#10071; Make sure the `CoreWaapService` is updated (the command above was executed)

### Check the logs to verify false positives are gone

Now after having reconfigured the `CoreWaapService` instance **wait for its configuration reload** (indicated by the log `add/update listener 'core.waap.listener'`) and observe the `socket.io` request denials disappear:

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  --since=3m \
  --follow \
  | grep 'add/update listener'
```{{exec}}

> &#8987; Wait until the `add/update listener 'core.waap.listener'` log message is seen indicating the configuration reload, otherwise the "old" configuration is still in use! The configuration reload might take a minute or two...

That's it! You have successfully extended the `CoreWaapService` resource configuration to handle a false positive!
