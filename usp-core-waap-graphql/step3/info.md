<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Explore GraphQL query `queryThreshold` settings
* How to find limits using Auto-Learning Tool

### GraphQL query `queryThreshold` settings

In addition to the `allowIntrospection` setting discovered in the previous step there are additional GraphQL settings available to configure:

* `queryThresholds.batchSize` : Number of operations (or sub-queries) included
* `queryThresholds.complexity`: Calculated [score](https://graphql.org/learn/security/#query-complexity-analysis) of how resource intensive a query is
* `queryThresholds.depth`     : How many levels of nested attributes a query uses

Let's have a closer look at what these settings are for an example GraphQL query:

```shell
     1  query GetUserDetails(: String!) {
     2    user(userId: ) {
     3      id
     4      email
     5      avatar
     6      displayName
     7      creationDate
     8      uuid
     9      groups {
    10        id
    11        displayName
    12      }
    13      attributes {
    14        name
    15        value
    16      }
    17    }
    18    schema {
    19      userSchema {
    20        attributes {
    21          name
    22          attributeType
    23          isList
    24          isVisible
    25          isEditable
    26          isHardcoded
    27          isReadonly
    28        }
    29      }
    30    }
    31  }
```

This example GraphQL query reflects

* `queryThresholds.batchSize` of 2 (operations / sub-queries for `user` and `schema`)
* `queryThresholds.complexity` of 24 (calculated valued based on query details)
* `queryThresholds.depth` of 5 (the lowest level of elements on lines 10,11,14,15,.. are on level 5)

Every setting can be tuned accordingly to allow as much complex GraphQL queries as needed by a specific application but not more.

> &#10071; Configuring the right settings will safeguard against resource overconsumption of the backend and by this reducing the risk of denial-of-service attacks.

While setting the right values for `queryThresholds.batchSize` and `queryThresholds.depth` is straight forward knowing the details of an application backend, the right setting for `queryThresholds.complexity` can be a challenge which we look into on the next section.

### How to find limits using Auto-Learning Tool

So far we have interacted with the LLDAP backend application using the console curl application, now lets use the provided WebUI and login to the application using the pre-configured administrative user:

* username: `admin`
* password: `insecure`

Click on the following link (opening up a new tab in your browser):

[LLDAP user interface]({{TRAFFIC_HOST1_80}})

> &#10071; Ensure you could successfully login to the application (there will be an error HTTP 403 shown in the user section)

You will notice that the application (accessed via USP Core WAAP enforcing GraphQL validation) does not work correctly, the possibility to [list users]({{TRAFFIC_HOST1_80}}/users) seems to be broken...

Let's have a look at the Core WAAP logs to identify what is going on here:

```shell
kubectl logs \
  -n lldap \
  -l app.kubernetes.io/name=usp-core-waap \
  --tail=-1 \
  | grep 'graphql_request_detected' \
  | sed -e 's/\[.*\] {/{/' \
  | jq
```{{exec}}

<details>
<summary>example command output</summary>

```shell
...
{
  "request.path": "/api/graphql",
  "crs.violated_rule": {
    "id": 109001,
    "category": "",
    "severity": "DEBUG",
    "data": "",
    "message": "GQL QUERY DETECTED",
    "matched_data": "TX",
    "matched_data_name": "graphql_request_detected",
    "tags": []
  },
  "client.address": "127.0.0.1",
  "transaction.id": "fe0040c9-a01e-4d63-b03f-f998824ef7f1",
  "crs.version": "",
  "request.id": "fe0040c9-a01e-4d63-b03f-f998824ef7f1"
}
{
  "request.path": "/api/graphql",
  "crs.violated_rule": {
    "id": 109008,
    "category": "",
    "severity": "DEBUG",
    "data": "",
    "message": "GraphQL Query: name=lldap-ref; complexity: detected=24, threshold=20; depth: detected=5, threshold=5; batch_size: detected=2, threshold=5; introspection: detected=0",
    "matched_data": "TX",
    "matched_data_name": "graphql_request_detected",
    "tags": [
      "CORE_WAAP_GRAPHQL"
    ]
  },
  "client.address": "127.0.0.1",
  "transaction.id": "fe0040c9-a01e-4d63-b03f-f998824ef7f1",
  "crs.version": "",
  "request.id": "fe0040c9-a01e-4d63-b03f-f998824ef7f1"
}
...
```

</details>
<br />

Indicated by the message having `crs.violated_rule.id:109008` there indeed was a GraphQL query blocked having a `complexity` of 24 while the threshold by default is set to 20.

Finding the correct (lowest) thresholds can be very time-consuming and cumbersome which is why the [Auto-Learning cli tool](https://docs.united-security-providers.ch/usp-core-waap/latest/downloads/) can be of great value!

The Auto-Learning cli tool is capable of parsing the log message while an application is being used and as such can provide a baseline configuration.

First use the following command to temporary allow all GraphQL queries (DETECT instead of BLOCK mode) and verify the setting afterwards:

```shell
kubectl patch \
  corewaapservices.waap.core.u-s-p.ch \
  lldap-usp-core-waap \
  -n lldap \
  --type='json' -p='[{"op":"replace","path":"/spec/routes/0/coraza/graphql/mode", "value":"DETECT"}]'
kubectl get \
  corewaapservices.waap.core.u-s-p.ch \
  lldap-usp-core-waap \
  -n lldap \
  -o json \
  | jq '.spec.routes[0].coraza.graphql.mode'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/lldap-usp-core-waap patched
"DETECT"
```

</details>
<br />

> &#128270; We use this step that subsequent GraphQL queries are executed (which would probably not be executed because of BLOCK mode)

Now switch back to the [LLDAP user interface]({{TRAFFIC_HOST1_80}}) browser tab and explore the application (make sure to click at least the use and group tab) then return here to run the Auto-Learning tool using writing an updated `waap.yaml` Resource config:

```shell
java -jar ~/waap-lib-autolearn-cli.jar \
 -n lldap \
 -w lldap-usp-core-waap \
 -o waap.yaml \
 graphql
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Processed log entries: 16.
```

</details>
<br />

Using the command below you can verify the proposed new settings

```shell
yq \
  '.spec.coraza.graphql.configs[0].queryThresholds' \
  waap.yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
complexity: 24
depth: 5
batchSize: 2
```

</details>
<br />

and apply them using either

```shell
kubectl apply -f waap.yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/lldap-usp-core-waap configured
```

</details>
<br />

Or just modify single queryThreshold settings using `kubectl patch` command (here `complexity`)

```shell
kubectl patch \
  corewaapservices.waap.core.u-s-p.ch \
  lldap-usp-core-waap \
  -n lldap \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/coraza/graphql/configs/0/queryThresholds", "value": {"complexity": 30}}]'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/lldap-usp-core-waap patched
```

</details>
<br />

And finally revert to BLOCK mode again using

```shell
kubectl patch \
  corewaapservices.waap.core.u-s-p.ch \
  lldap-usp-core-waap \
  -n lldap \
  --type='json' -p='[{"op":"replace","path":"/spec/routes/0/coraza/graphql/mode", "value":"BLOCK"}]'
kubectl get \
  corewaapservices.waap.core.u-s-p.ch \
  lldap-usp-core-waap \
  -n lldap \
  -o json \
  | jq '.spec.routes[0].coraza.graphql.mode'
```{{exec}}

<details>
<summary>example command output</summary>

```shell
corewaapservice.waap.core.u-s-p.ch/lldap-usp-core-waap patched
"BLOCK"
```

</details>
<br />

Now re-try the [LLDAP user interface]({{TRAFFIC_HOST1_80}}) where every previously accessed areas should work (note if you use new areas in the UI you didn't access before you probably have to re-learn the logs).

That's it! You have extended the `CoreWaapService` resource configuration to handle GraphQL threshold limits using the auto-learning cli tool!
