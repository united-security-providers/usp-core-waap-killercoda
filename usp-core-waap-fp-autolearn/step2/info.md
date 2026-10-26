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
[2026-10-26 13:52:11.579029][error][golang][/src/internal/config/config.go:292][coraza-waf] msg="WAF rule triggered: Request content type is not allowed by policy" tx="3170c59b-7c56-45cb-b2f0-89802c863551" hostname="192.168.0.29" uri="/socket.io/?EIO=4&transport=polling&t=bfswnw6o&sid=0zJ3NfWkygc_wBY-AAAA" client="10.244.5.252" crs.version="OWASP_CRS/4.25.1" crs.violated_rule.id="920420" crs.violated_rule.revision="" crs.violated_rule.version="OWASP_CRS/4.25.1" crs.violated_rule.file="@owasp_crs/REQUEST-920-PROTOCOL-ENFORCEMENT.conf" crs.violated_rule.line="1653" crs.violated_rule.message="Request content type is not allowed by policy" crs.violated_rule.data="|text/plain|" crs.violated_rule.severity="critical" crs.violated_rule.maturity="0" crs.violated_rule.accuracy="0" crs.violated_rule.category="REQUEST-920-PROTOCOL-ENFORCEMENT" crs.violated_rule.tags="[application-multi language-multi platform-multi attack-protocol paranoia-level/1 OWASP_CRS OWASP_CRS/PROTOCOL-ENFORCEMENT capec/1000/255/153]" crs.violated_rule.match.name="REQUEST_HEADERS" crs.violated_rule.match.key="content-type" crs.violated_rule.match.op="" crs.violated_rule.match.value="text/plain;charset=UTF-8" request-id="3170c59b-7c56-45cb-b2f0-89802c863551"
[2026-10-26 13:52:11.579321][error][golang][/src/internal/config/config.go:299][coraza-waf] msg="WAF rule triggered: Inbound Anomaly Score Exceeded (Total Score: 5)" tx="3170c59b-7c56-45cb-b2f0-89802c863551" hostname="192.168.0.29" uri="/socket.io/?EIO=4&transport=polling&t=bfswnw6o&sid=0zJ3NfWkygc_wBY-AAAA" client="10.244.5.252" crs.version="OWASP_CRS/4.25.1" crs.violated_rule.id="949110" crs.violated_rule.revision="" crs.violated_rule.version="OWASP_CRS/4.25.1" crs.violated_rule.file="@owasp_crs/REQUEST-949-BLOCKING-EVALUATION.conf" crs.violated_rule.line="11628" crs.violated_rule.message="Inbound Anomaly Score Exceeded (Total Score: 5)" crs.violated_rule.data="" crs.violated_rule.severity="unknown" crs.violated_rule.maturity="0" crs.violated_rule.accuracy="0" crs.violated_rule.category="REQUEST-949-BLOCKING-EVALUATION" crs.violated_rule.tags="[anomaly-evaluation OWASP_CRS]" crs.violated_rule.match.name="TX" crs.violated_rule.match.key="blocking_inbound_anomaly_score" crs.violated_rule.match.op="" crs.violated_rule.match.value="5" request-id="3170c59b-7c56-45cb-b2f0-89802c863551"
[2026-10-26 13:52:11.579976][error][golang][/src/internal/config/config.go:299][coraza-waf] msg="WAF rule triggered: Anomaly Scores: (Inbound Scores: blocking=5, detection=5, per_pl=5-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=0, RCE=0, PHPI=0, HTTP=0, SESS=0, COMBIN" tx="3170c59b-7c56-45cb-b2f0-89802c863551" hostname="192.168.0.29" uri="/socket.io/?EIO=4&transport=polling&t=bfswnw6o&sid=0zJ3NfWkygc_wBY-AAAA" client="10.244.5.252" crs.version="OWASP_CRS/4.25.1" crs.violated_rule.id="980170" crs.violated_rule.revision="" crs.violated_rule.version="OWASP_CRS/4.25.1" crs.violated_rule.file="@owasp_crs/RESPONSE-980-CORRELATION.conf" crs.violated_rule.line="12045" crs.violated_rule.message="Anomaly Scores: (Inbound Scores: blocking=5, detection=5, per_pl=5-0-0-0, threshold=5) - (Outbound Scores: blocking=0, detection=0, per_pl=0-0-0-0, threshold=4) - (SQLI=0, XSS=0, RFI=0, LFI=0, RCE=0, PHPI=0, HTTP=0, SESS=0, COMBINED_SCORE=5)" crs.violated_rule.data="" crs.violated_rule.severity="unknown" crs.violated_rule.maturity="0" crs.violated_rule.accuracy="0" crs.violated_rule.category="RESPONSE-980-CORRELATION" crs.violated_rule.tags="[reporting OWASP_CRS]" crs.violated_rule.match.name="UNKNOWN" crs.violated_rule.match.key="" crs.violated_rule.match.op="" crs.violated_rule.match.value="" request-id="3170c59b-7c56-45cb-b2f0-89802c863551"
```

</details>
<br />

Notice the high amount of `uri="/socket.io/?...` requests being blocked seen in the previous scenario?

Now during the false positives introduction scenario you analyzed the USP Core WAAP logs using out-of-the-box Kubernetes / Linux tools and now you will use the **auto-learning** cli tool for instead!

Go ahead and download the Auto-Learning [java cli tool](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/downloads/) using

```shell
curl -fso /tmp/waap-lib-autolearn-cli-2.1.0.jar \
 https://docs.united-security-providers.ch/usp-core-waap/2.1.x/files/waap-lib-autolearn-cli-2.1.0.jar || echo "failed to download auto-learning cli tool version 2.1.0, exiting..."
```{{exec}}

Next execute it showing the help page using

```shell
java -jar /tmp/waap-lib-autolearn-cli-2.1.0.jar --help
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Usage: java -jar waap-lib-autolearn-cli-<version>.jar [-hV] [[-i=<specIn>]
       [-l=<log>]] [-n=<namespace> -w=<instance>] [[-o=<specOut>]] [[crs]
       [graphql] [methods]] [[-t=<range>] [-e=<errorFile>] [-s]]
       [[--skippostparts] [--skipmetadataexport] [--sortexceptions]
       [--reduceconfigured]]
Autolearns CRS rule exceptions and methods whitelisting from USP Core WAAP log
files.
Copyright (c) United Security Providers AG, Switzerland, All rights reserved.
  -h, --help                 Show this help message and exit.
  -V, --version              Print version information and exit.
file input
  -i, --waapspecin=<specIn>  USP Core WAAP spec file (or manifest file) to
                               read, use '-' for stdin; if not given, the spec
                               is read from Kubernetes (needs -n/-w).
  -l, --log=<log>            USP Core WAAP log file to parse; if not given, the
                               logs are read from Kubernetes (needs -n/-w).
k8s instance input
  -n, --namespace=<namespace>
                             Kubernetes namespace with USP Core WAAP; provides
                               spec and/or logs not read from files.
  -w, --waapinstance=<instance>
                             Kubernetes USP Core WAAP instance name (app.
                               kubernetes.io/instance); used together with -n.
output
  -o, --waapspecout=<specOut>
                             USP Core WAAP spec file (or manifest file) to
                               write, defaults to 'waap.yaml', use '-' for
                               stdout (then automatically also -s).
processors
      crs                    Autolearns CRS rule exceptions
      graphql                Autolearns max. values for GraphQL queries
      methods                Autolearns HTTP methods whitelisting
common options
  -e, --errorfile=<errorFile>
                             File to write errors to, optional, by default no
                               file is written.
  -s, --silent               No output to stdout with number of learned rules
                               and errors.
  -t, --timerange=<range>    Optional time range to learn from, e.g.
                               "20231201.1010-20231202.1010" (time with
                               minutes).
CRS mode options
      --reduceconfigured     Changes already configured exceptions by removing
                               a) duplicates & b) more specific rules in favor
                               of more general ones
      --skipmetadataexport   Skip metadata export.
      --skippostparts        Skip part name parsing for ARGS_POST.
      --sortexceptions       Sort rule exceptions in the output.
```

</details>
<br />

> &#8987; Make sure this step is successful and you see the help overview prior to continue!

Now lets use the auto-learning tool to parse our **running USP Core WAAP instance** and generate rule exceptions by executing

```shell
java -jar /tmp/waap-lib-autolearn-cli-2.1.0.jar \
 -n juiceshop \
 -w juiceshop-usp-core-waap \
 -o waap.yaml \
 crs
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Learned request/response rule exceptions: 2/0.
```

</details>
<br />

By default a file called `waap.yaml` is written to the current directory containing an updated instance configuration. The tool only adds what was learned (implicit defaults are not turned into explicit settings) and strips server-side fields (like `status` or `metadata.resourceVersion`) from the resource.

> &#128270; The `crs` processor also supports options like `--sortexceptions` (sort the rule exceptions for a consistent output) and `--reduceconfigured` (merge already configured exceptions where possible), see the [auto-learning documentation](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/operation/autolearning/).

> &#10071; Do **NOT** just apply auto generated configurations without prior validation!

Inspecting the generated config (`less waap.yaml`) or by specifically looking at rule exceptions by executing the command below we get the rule exceptions:

```shell
yq e '.spec.coraza.crs.requestRuleExceptions' waap.yaml
```{{exec}}


<details>
<summary>example command output</summary>

```shell
- ruleIds:
    - 942100
  requestPartType: "ARGS_POST"
  requestPartName: "json.email"
  location: "/rest/user/login"
  metadata:
    comment: "SQL Injection Attack Detected via libinjection"
    date: "2024-11-21"
    createdBy: "autolearning"
- ruleIds:
    - 920420
  requestPartType: "REQUEST_HEADERS"
  requestPartName: "content-type"
  location: "/socket.io/"
  metadata:
    comment: "Request content type is not allowed by policy"
    date: "2024-11-21"
    createdBy: "autolearning"
```

</details>
<br />

### Reconfigure the USP Core WAAP instance to eliminate (or mitigate) false positives

In addition to the wanted `socket.io` exception the SQL-injection attempt is also listed here (learned from the access logs!). So **don't just apply learned exceptions without prior validation** as this would allow the SQL-injection again!

You want these `/socket.io` requests to succeed (in this use-case the block of these requests is a `false positive`) and therefore you add an exception rule to the Core WAAP `CRS` configuration using `requestRuleExceptions`:

```yaml
...
spec:
  coraza:
    crs:
      requestRuleExceptions:
      - location: "/socket.io/"
        ruleIds:
          - 920420
        requestPartType: "REQUEST_HEADERS"
        requestPartName: "content-type"
        metadata:
          comment: "Request content type is not allowed by default policy"
          date: "2024-11-21"
          createdBy: "autolearning"
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

> &#10071; Make sure the `CoreWaapService` is updated (the command above was executed)!

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

After the reload follow the Core WAAP logs for any new `/socket.io` blocks (stops the command above):

```shell
kubectl logs \
  -n juiceshop \
  -l app.kubernetes.io/name=usp-core-waap-proxy \
  --tail=0 \
  --follow \
  | grep '\[coraza-waf\].*uri="/socket.io'
```{{exec interrupt}}

Now [access the Juice Shop]({{TRAFFIC_HOST1_30090}}) again (or reload its browser tab) generating new `/socket.io` requests: no more log lines should appear, as these requests are no longer blocked. Stop following the logs using `Ctrl+C`{{}}.

At last again [access the Juice Shop]({{TRAFFIC_HOST1_30090}}/#/login) web application using your browser and try to execute an SQL-injection by logging in with:

* email `' OR true;` and
* password `fail` (or anything else except empty)

> &#10071; The attempt still must fail (if not check the added `coraza.crs.requestRuleExceptions` configuration)!

That's it! You have successfully extended the `CoreWaapService` resource configuration to handle a false positive using the auto-learning cli tool!
