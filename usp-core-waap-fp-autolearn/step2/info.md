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

Notice the high amount of `"request.path":"/socket.io/?...` requests being blocked seen in the previous scenario?

Now during the false positives introduction scenario you analyzed the USP Core WAAP logs using out-of-the-box kubernetes / linux tools and now you will use the **auto-learning** cli tool for instead!

Go ahead and download the java cli tool using

```shell
version=$(helm list -n usp-core-waap-operator -o json | jq -r '.[] | select(.name == "usp-core-waap-operator") | .app_version')
curl -so /tmp/waap-lib-autolearn-cli-${version}.jar \
 https://docs.united-security-providers.ch/usp-core-waap/files/waap-lib-autolearn-cli-${version}.jar || echo "failed to download version ${version}, exiting..."
```{{exec}}

Next execute it showing the help page using

```shell
java -jar /tmp/waap-lib-autolearn-cli-${version}.jar --help
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Usage: java -jar waap-lib-autolearn-cli-<version>.jar [-hsV]
       [--reduceconfigured] [--skipmetadataexport] [--skippostparts]
       [--sortexceptions] [-e=<error>] [-i=<specIn>] [-l=<log>]
       [-n=<namespace>] [-o=<specOut>] [-t=<range>] [-w=<instance>]
Autolearns CRS rule exceptions from USP Core WAAP log files.
Copyright (c) United Security Providers AG, Switzerland, All rights reserved.
  -e, --errorfile=<error>    File to write errors to, optional, by default no
                               file is written.
  -h, --help                 Show this help message and exit.
  -i, --waapspecin=<specIn>  USP Core WAAP spec file (or manifest file) to
                               read, use '-' for stdin, exclusive with -n/-w.
  -l, --log=<log>            USP Core WAAP log file to parse, exclusive with
                               -n/-w.
  -n, --namespace=<namespace>
                             Kubernetes namespace with USP Core WAAP, exclusive
                               with -i/-l.
  -o, --waapspecout=<specOut>
                             USP Core WAAP spec file (or manifest file) to
                               write, defaults to 'waap.yaml', use '-' for
                               stdout (then automatically also -s).
      --reduceconfigured     Changes already configured exceptions by removing
                               a) duplicates & b) more specific rules in favor
                               of more general ones
  -s, --silent               No output to stdout with number of learned rules
                               and errors.
      --skipmetadataexport   Skip metadata export.
      --skippostparts        Skip part name parsing for ARGS_POST.
      --sortexceptions       Sort rule exceptions in the output.
  -t, --timerange=<range>    Optional time range to learn from, e.g.
                               "20231201.1010-20231202.1010" (time with
                               minutes).
  -V, --version              Print version information and exit.
  -w, --waapinstance=<instance>
                             Kubernetes USP Core WAAP instance name (app.
                               kubernetes.io/instance), exclusive with -i/-l.
```
</details>
<br />

> &#8987; Make sure this step is successful and you see the help overview prior to continue!

Now lets use the auto-learning tool to parse our **running USP Core WAAP instance** and generate rule exceptions by executing

```shell
java -jar /tmp/waap-lib-autolearn-cli-${version}.jar \
 -n juiceshop \
 -w juiceshop-usp-core-waap
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Learned request/response rule exceptions: 2/0.
```

</details>
<br />

By default a file called `waap.yaml` is written to the current directory containing an updated instance configuration.

> &#10071; Do **NOT** just apply auto generated configurations without prior validation!

Inspecting the generated config (`less waap.yaml`) or by specifically looking at rule exceptions by executing the command below we get the rule exceptions:

```shell
yq e '.spec.crs.requestRuleExceptions' waap.yaml
```{{exec}}


<details>
<summary>example command output</summary>

```shell
- ruleId: 942100
  requestPartType: "ARGS_POST"
  requestPartName: "json.email"
  location: "/rest/user/login"
  metadata:
    comment: "SQL Injection Attack Detected via libinjection"
    date: "2024-11-21"
    createdBy: "autolearning"
- ruleId: 920420
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

You want these `/socket.io` requests to succeed (in this use-case the block of these requests is a `false positive`) and therefore you add an exception rule to the core-waap `CRS` configuration using `requestRuleExceptions`:

```yaml
...
spec:
  crs:
    requestRuleExceptions:
    - ruleId: 920420
      requestPartType: "REQUEST_HEADERS"
      requestPartName: "content-type"
      location: "/socket.io/"
      metadata:
        comment: "Request content type is not allowed by policy"
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

At last again [access the Juice Shop]({{TRAFFIC_HOST1_80}}/login) web application using your browser and try to execute an SQL-injection by logging in with:

* email `' OR true;` and
* password `fail` (or anything else except empty)

> &#10071; The attempt still must fail (if not check the added `crs.requestRuleExceptions` configuration)!

That's it! You have successfully extended the `CoreWaapService` resource configuration to handle a false positive using the auto-learning cli tool!
