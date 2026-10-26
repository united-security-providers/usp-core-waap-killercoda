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
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[coraza-waf\].*uri="/socket.io'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
[2026-10-26 13:38:54.701830][error][golang][/src/internal/config/config.go:299][coraza-waf] msg="WAF rule triggered: Request content type is not allowed by policy" tx="9035d989-d579-4499-bb37-f4e2fded7db3" hostname="192.168.0.62" uri="/socket.io/?EIO=4&transport=polling&t=ayr6mwz6&sid=oEczdW_EBvM2O3ZeAAAb" client="10.244.3.225" crs.version="OWASP_CRS/4.25.1" crs.violated_rule.id="920420" crs.violated_rule.revision="" crs.violated_rule.version="OWASP_CRS/4.25.1" crs.violated_rule.file="@owasp_crs/REQUEST-920-PROTOCOL-ENFORCEMENT.conf" crs.violated_rule.line="..." crs.violated_rule.message="Request content type is not allowed by policy" crs.violated_rule.data="|text/plain|" crs.violated_rule.severity="critical" crs.violated_rule.maturity="0" crs.violated_rule.accuracy="0" crs.violated_rule.category="REQUEST-920-PROTOCOL-ENFORCEMENT" crs.violated_rule.tags="[application-multi language-multi platform-multi attack-protocol paranoia-level/1 OWASP_CRS OWASP_CRS/PROTOCOL-ENFORCEMENT capec/1000/255/153 PCI/12.1]" crs.violated_rule.match.name="REQUEST_HEADERS" crs.violated_rule.match.key="content-type" crs.violated_rule.match.op="" crs.violated_rule.match.value="text/plain" request-id="9035d989-d579-4499-bb37-f4e2fded7db3"
[2026-10-26 13:38:54.702120][error][golang][/src/internal/config/config.go:299][coraza-waf] msg="WAF rule triggered: Inbound Anomaly Score Exceeded (Total Score: 5)" tx="9035d989-d579-4499-bb37-f4e2fded7db3" hostname="192.168.0.62" uri="/socket.io/?EIO=4&transport=polling&t=ayr6mwz6&sid=oEczdW_EBvM2O3ZeAAAb" client="10.244.3.225" crs.version="OWASP_CRS/4.25.1" crs.violated_rule.id="949110" crs.violated_rule.revision="" crs.violated_rule.version="OWASP_CRS/4.25.1" crs.violated_rule.file="@owasp_crs/REQUEST-949-BLOCKING-EVALUATION.conf" crs.violated_rule.line="11628" crs.violated_rule.message="Inbound Anomaly Score Exceeded (Total Score: 5)" crs.violated_rule.data="" crs.violated_rule.severity="unknown" crs.violated_rule.maturity="0" crs.violated_rule.accuracy="0" crs.violated_rule.category="REQUEST-949-BLOCKING-EVALUATION" crs.violated_rule.tags="[anomaly-evaluation OWASP_CRS]" crs.violated_rule.match.name="TX" crs.violated_rule.match.key="blocking_inbound_anomaly_score" crs.violated_rule.match.op="" crs.violated_rule.match.value="5" request-id="9035d989-d579-4499-bb37-f4e2fded7db3"
[2026-10-26 13:38:54.702775][error][golang][/src/internal/config/config.go:299][coraza-waf] msg="WAF rule triggered: Anomaly Scores: (Inbound Scores: blocking=5, detection=5, per_pl=5-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=0, RCE=0, PHPI=0, HTTP=0, SESS=0, COMBIN" tx="9035d989-d579-4499-bb37-f4e2fded7db3" hostname="192.168.0.62" uri="/socket.io/?EIO=4&transport=polling&t=ayr6mwz6&sid=oEczdW_EBvM2O3ZeAAAb" client="10.244.3.225" crs.version="OWASP_CRS/4.25.1" crs.violated_rule.id="980170" crs.violated_rule.revision="" crs.violated_rule.version="OWASP_CRS/4.25.1" crs.violated_rule.file="@owasp_crs/RESPONSE-980-CORRELATION.conf" crs.violated_rule.line="12045" crs.violated_rule.message="Anomaly Scores: (Inbound Scores: blocking=5, detection=5, per_pl=5-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=0, RCE=0, PHPI=0, HTTP=0, SESS=0, COMBINED_SCORE=5)" crs.violated_rule.data="" crs.violated_rule.severity="unknown" crs.violated_rule.maturity="0" crs.violated_rule.accuracy="0" crs.violated_rule.category="RESPONSE-980-CORRELATION" crs.violated_rule.tags="[reporting OWASP_CRS]" crs.violated_rule.match.name="UNKNOWN" crs.violated_rule.match.key="" crs.violated_rule.match.op="" crs.violated_rule.match.value="" request-id="9035d989-d579-4499-bb37-f4e2fded7db3"
```

</details>
<br />

Notice the high amount of `uri="/socket.io/?...` requests being blocked?

The log message is split into two parts: First part in square brackets `[...]` containing the generic envoy log information (timestamp, log level and the module taking action, which in our use-case is the [coraza web application firewall](https://github.com/corazawaf/coraza) module `coraza-waf`) and the second part which is the actual payload formatted as `key="value"` pairs. All log lines of the same request share the same transaction id `tx`.

Using the following command you can extract the most relevant fields and hereby as a human have better insight into the actual action:

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[coraza-waf\].*uri="/socket.io' \
  | sed -E 's/.*tx="([^"]*)".*uri="([^"?]*)[^"]*".*crs\.violated_rule\.id="([0-9]+)".*crs\.violated_rule\.message="([^"]*)".*/tx=\1 rule=\3 uri=\2 : \4/'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
tx=9035d989-d579-4499-bb37-f4e2fded7db3 rule=920420 uri=/socket.io/ : Request content type is not allowed by policy
tx=9035d989-d579-4499-bb37-f4e2fded7db3 rule=949110 uri=/socket.io/ : Inbound Anomaly Score Exceeded (Total Score: 5)
tx=9035d989-d579-4499-bb37-f4e2fded7db3 rule=980170 uri=/socket.io/ : Anomaly Scores: (Inbound Scores: blocking=5, detection=5, per_pl=5-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=0, RCE=0, PHPI=0, HTTP=0, SESS=0, COMBINED_SCORE=5)
```

</details>

> &#128270; Look out for the `crs.violated_rule.id` field which contains the Core Rule Set rule number triggering the action.

The field `crs.violated_rule.id` indicates what Core Rule Set Rule has triggered. The `Rule ID 920420` blocks this request because the content-type is `text/plain` (see `crs.violated_rule.data`) which is untrusted.

> &#128270; The Rule IDs in the 949... range are the blocking condition rules and the ones in the 980... range are reporting rules, both are not of interest. In our case the **Rule ID 920420** (Protocol enforcement) is.

### Reconfigure the USP Core WAAP instance to eliminate (or mitigate) false positives

You want these `/socket.io` requests to succeed (in this use-case the block of these requests is a `false positive`) and therefore you add an exception rule to the core-waap `CRS` configuration using [`coraza.crs.requestRuleExceptions`](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/crd-doc/#corewaapservicespeccorazacrsrequestruleexceptionsindex):

```yaml
...
spec:
  coraza:
    crs:
      requestRuleExceptions:
      - ruleIds:
          - 920420
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
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=100 \
  --follow \
  | grep 'add/update listener'
```{{exec}}

> &#8987; Wait until the `add/update listener 'core.waap.listener` log message is seen indicating the configuration reload, otherwise the "old" configuration is still in use! The configuration reload might take a minute or two...

After the reload check the Core WAAP logs again for any new `/socket.io` entries (there should be no after the reload time)

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=-1 \
  | grep '\[coraza-waf\].*uri="/socket.io'
```{{exec}}

That's it! You have successfully extended the `CoreWaapService` resource configuration to handle a false positive!
