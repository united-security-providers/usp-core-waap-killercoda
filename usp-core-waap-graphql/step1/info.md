<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Access LLDAP demo application using GraqhQL
* Execute a GraphQL introspection query
* Explore GraphQL security

### Access LLDAP demo application using GraphQL

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see an `HTTP 502 Bad Gateway` error)!

In this scenario the [LLDAP](https://github.com/lldap/lldap/) backend application has been setup and will be accessed via GraphQL. In order to access the API, the required authentication token has been prepared and is available via `$LLDAP_TOKEN`. Now execute the following command in order to query what groups exists within the LLDAP backend:

> &#128270; Initially the backend will be accessed unprotected (not using USP Core WAAP)

```shell
curl -v 'http://localhost:8080/api/graphql' \
   -H 'Content-Type: application/json' \
   --silent \
   --cookie "token=$LLDAP_TOKEN" \
   --data '{"query": "query { groups { displayName } }"}' | jq
```{exec}

<details>
<summary>example command output</summary>

```shell
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> POST /api/graphql HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> Cookie: token=...
> Content-Type: application/json
> Content-Length: 45
>
} [45 bytes data]
< HTTP/1.1 200 OK
< content-length: 162
< content-type: application/json
< date: Tue, 14 Oct 2025 12:00:36 GMT
<
{ [162 bytes data]
* Connection #0 to host localhost left intact
{
  "data": {
    "groups": [
      {
        "displayName": "lldap_admin"
      },
      {
        "displayName": "lldap_password_manager"
      },
      {
        "displayName": "lldap_strict_readonly"
      }
    ]
  }
}
```

</details>
<br />

> &#8987; Verify that you received a JSON-formatted list of user groups like shown in the example output above!

### Execute a GraphQL introspection query

The GraphQL language support a special query called [introspection](https://graphql.org/learn/introspection/) which are a special type of queries enabling one to "learn" the GraphQL API schema (and by that the underlaying data scheme). While for developers this is a useful feature of GraphQL from an security operations perspective this is not ideal enabling attackers to gain knowledge about application internals and should be blocked.

Go ahead and make a GraphQL introspection query against the LLDAP API:


```shell
curl -v 'http://localhost:8080/api/graphql' \
   -H 'Content-Type: application/json' \
   --silent \
   --cookie "token=$LLDAP_TOKEN" \
   --data '{"query": "query { __schema { types { name }} }"}'
```{exec}
<details>
<summary>example command output</summary>

```shell
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> POST /api/graphql HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> Cookie: token=...
> Content-Type: application/json
> Content-Length: 49
>
} [49 bytes data]
< HTTP/1.1 200 OK
< content-length: 694
< content-type: application/json
< date: Tue, 14 Oct 2025 13:36:22 GMT
<
{ [694 bytes data]
* Connection #0 to host localhost left intact
{
  "data": {
    "__schema": {
      "types": [
        {
          "name": "AttributeValue"
        },
        {
          "name": "Mutation"
        },
        {
          "name": "Group"
        },
        {
          "name": "RequestFilter"
        },
        {
          "name": "DateTimeUtc"
        },
        {
          "name": "__Type"
        },
        {
          "name": "__Schema"
        },
        {
          "name": "Int"
        },
        {
          "name": "Query"
        },
        {
          "name": "CreateUserInput"
        },
        {
          "name": "AttributeSchema"
        },
        {
          "name": "UpdateUserInput"
        },
        {
          "name": "Boolean"
        },
        {
          "name": "EqualityConstraint"
        },
        {
          "name": "__InputValue"
        },
        {
          "name": "String"
        },
        {
          "name": "__Field"
        },
        {
          "name": "__TypeKind"
        },
        {
          "name": "Schema"
        },
        {
          "name": "UpdateGroupInput"
        },
        {
          "name": "__EnumValue"
        },
        {
          "name": "AttributeValueInput"
        },
        {
          "name": "CreateGroupInput"
        },
        {
          "name": "User"
        },
        {
          "name": "AttributeType"
        },
        {
          "name": "AttributeList"
        },
        {
          "name": "__DirectiveLocation"
        },
        {
          "name": "Success"
        },
        {
          "name": "__Directive"
        }
      ]
    }
  }
}
```

</details>
<br />

### GraphQL security

There are some security concerns which should be considered when operating GraphQL APIs. As outlined in the [GraphQL security section](https://graphql.org/learn/security/), there are techniques which can help protect GraphQL API endpoints by reducing the attack vectors. These include but are not limited to:

* [Depth limiting](https://graphql.org/learn/security/#depth-limiting)
* [Breadth and batch limiting](https://graphql.org/learn/security/#breadth-and-batch-limiting)
* [Query complexity analysis](https://graphql.org/learn/security/#query-complexity-analysis)
* [Introspection](https://graphql.org/learn/security/#introspection)

Let's see how [GraphQL validation](https://docs.united-security-providers.ch/usp-core-waap/latest/coraza-graphql/) **provided by USP Core WAAP** safeguards you in the next step!
