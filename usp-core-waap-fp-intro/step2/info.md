<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

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
  | grep "\[critical\]\[golang\]" \
  | grep -E '"request.path":"[^"]*"'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
[2025-05-26 09:40:15.995][18][critical][golang] [contrib/golang/common/log/cgo.cc:27] {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PSBzjVD\u0026sid=GEuKasFV0AtHcsdCAAAo","crs.violated_rule":{"id":949110,"category":"REQUEST-949-BLOCKING-EVALUATION","severity":"EMERGENCY","data":"","message":"Inbound Anomaly Score Exceeded (Total Score: 5)","matched_data":"TX","matched_data_name":"blocking_inbound_anomaly_score","tags":["anomaly-evaluation","OWASP_CRS"]},"client.address":"127.0.0.1","transaction.id":"d9f72163-b357-48c7-9566-df19aaa97740","crs.version":"OWASP_CRS/4.14.0","request.id":"d9f72163-b357-48c7-9566-df19aaa97740"}
[2025-05-26 09:40:16.943][18][critical][golang] [contrib/golang/common/log/cgo.cc:27] {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PSBzjkA\u0026sid=hwsN5Wz_nIUsrzjjAAAp","crs.violated_rule":{"id":920420,"category":"REQUEST-920-PROTOCOL-ENFORCEMENT","severity":"CRITICAL","data":"|text/plain|","message":"Request content type is not allowed by policy","matched_data":"REQUEST_HEADERS","matched_data_name":"content-type","tags":["application-multi","language-multi","platform-multi","attack-protocol","paranoia-level/1","OWASP_CRS","OWASP_CRS/PROTOCOL-ENFORCEMENT","capec/1000/255/153","PCI/12.1"]},"client.address":"127.0.0.1","transaction.id":"07015c03-33aa-4b30-b3cf-54676ca2dd33","crs.version":"OWASP_CRS/4.14.0","request.id":"07015c03-33aa-4b30-b3cf-54676ca2dd33"}
[2025-05-26 09:40:16.949][18][critical][golang] [contrib/golang/common/log/cgo.cc:27] {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PSBzjkA\u0026sid=hwsN5Wz_nIUsrzjjAAAp","crs.violated_rule":{"id":949110,"category":"REQUEST-949-BLOCKING-EVALUATION","severity":"EMERGENCY","data":"","message":"Inbound Anomaly Score Exceeded (Total Score: 5)","matched_data":"TX","matched_data_name":"blocking_inbound_anomaly_score","tags":["anomaly-evaluation","OWASP_CRS"]},"client.address":"127.0.0.1","transaction.id":"07015c03-33aa-4b30-b3cf-54676ca2dd33","crs.version":"OWASP_CRS/4.14.0","request.id":"07015c03-33aa-4b30-b3cf-54676ca2dd33"}
[2025-05-26 09:40:16.987][18][critical][golang] [contrib/golang/common/log/cgo.cc:27] {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PSBzjkh\u0026sid=hwsN5Wz_nIUsrzjjAAAp","crs.violated_rule":{"id":920420,"category":"REQUEST-920-PROTOCOL-ENFORCEMENT","severity":"CRITICAL","data":"|text/plain|","message":"Request content type is not allowed by policy","matched_data":"REQUEST_HEADERS","matched_data_name":"content-type","tags":["application-multi","language-multi","platform-multi","attack-protocol","paranoia-level/1","OWASP_CRS","OWASP_CRS/PROTOCOL-ENFORCEMENT","capec/1000/255/153","PCI/12.1"]},"client.address":"127.0.0.1","transaction.id":"db6edfa7-43f0-4296-9cff-1a658f9e0d98","crs.version":"OWASP_CRS/4.14.0","request.id":"db6edfa7-43f0-4296-9cff-1a658f9e0d98"}
[2025-05-26 09:40:16.996][18][critical][golang] [contrib/golang/common/log/cgo.cc:27] {"request.path":"/socket.io/?EIO=4\u0026transport=polling\u0026t=PSBzjkh\u0026sid=hwsN5Wz_nIUsrzjjAAAp","crs.violated_rule":{"id":949110,"category":"REQUEST-949-BLOCKING-EVALUATION","severity":"EMERGENCY","data":"","message":"Inbound Anomaly Score Exceeded (Total Score: 5)","matched_data":"TX","matched_data_name":"blocking_inbound_anomaly_score","tags":["anomaly-evaluation","OWASP_CRS"]},"client.address":"127.0.0.1","transaction.id":"db6edfa7-43f0-4296-9cff-1a658f9e0d98","crs.version":"OWASP_CRS/4.14.0","request.id":"db6edfa7-43f0-4296-9cff-1a658f9e0d98"}
```

</details>
<br />

Notice the high amount of `"request.path":"/socket.io/?...` requests being blocked?

The log message is split into two parts: First part prior to first curly brace `{` containing the generic envoy log information indicating what module is taking action, which in our use-case is the [coraza web application firewall](https://github.com/corazawaf/coraza) module and the second part which is the actual payload log formatted as JSON.

Using the following command you can parse the JSON output and hereby as a human have better insight into the actual action:

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep "golang.*/socket.io" \
  | sed -e 's/\[.*\] {/{/' \
  | jq
```{{exec}}

<details>
<summary>example command output</summary>

```json
{
  "request.path": "/socket.io/?EIO=4&transport=polling&t=PSB_q_0&sid=1r8gBB93xoXcfFf3AAGA",
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
      "OWASP_CRS/PROTOCOL-ENFORCEMENT",
      "capec/1000/255/153",
      "PCI/12.1"
    ]
  },
  "client.address": "127.0.0.1",
  "transaction.id": "1581a900-dd36-439b-8f70-4675c5221646",
  "crs.version": "OWASP_CRS/4.14.0",
  "request.id": "1581a900-dd36-439b-8f70-4675c5221646"
}
{
  "request.path": "/socket.io/?EIO=4&transport=polling&t=PSB_q_0&sid=1r8gBB93xoXcfFf3AAGA",
  "crs.violated_rule": {
    "id": 949110,
    "category": "REQUEST-949-BLOCKING-EVALUATION",
    "severity": "EMERGENCY",
    "data": "",
    "message": "Inbound Anomaly Score Exceeded (Total Score: 5)",
    "matched_data": "TX",
    "matched_data_name": "blocking_inbound_anomaly_score",
    "tags": [
      "anomaly-evaluation",
      "OWASP_CRS"
    ]
  },
  "client.address": "127.0.0.1",
  "transaction.id": "1581a900-dd36-439b-8f70-4675c5221646",
  "crs.version": "OWASP_CRS/4.14.0",
  "request.id": "1581a900-dd36-439b-8f70-4675c5221646"
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

Now after having reconfigured the `CoreWaapService` instance **wait for its configuration reload** (indicated by the log `add/update listener 'core.waap.listener'`) and observe the `socket.io` request denials disappear.

Execute

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  --since=3m \
  --follow \
  | grep 'add/update listener'
```{{exec}}

> &#8987; Wait until the `add/update listener 'core.waap.listener` log message is seen indicating the configuration reload, otherwise the "old" configuration is still in use! The configuration reload might take a minute or two...

After the reload check the Core WAAP logs again for any new `/socket.io` entries (there should be no after the reload time)

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap \
  | grep "\[critical\]\[golang\]" \
  | grep -E '"request.path":"[^"]*"'
```{{exec}}

That's it! You have successfully extended the `CoreWaapService` resource configuration to handle a false positive!
