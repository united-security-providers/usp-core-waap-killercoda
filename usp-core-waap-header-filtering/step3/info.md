<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Learn more about header filtering configuration

As seen by this demo here, the default configuration of USP Core WAAP header filtering protects by the fact that unlisted request and response headers are removed. In this last step we will dive into the configuration options available to customize the header filtering feature if needed.

### Header filtering configuration

> &#128270; Refer to the [header filtering documentation](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/header-filtering/) for a complete description and the [API reference](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/crd-doc/#corewaapservicespecheaderfilter) for all available configuration options.

By inspecting the list of headers against a list of predefined headers and custom allowed / denied headers, the feature will remove headers accordingly.

The feature is configured within the USP Core WAAP Kubernetes resource CoreWaapService via `spec.headerFilter`, which holds a list of named, reusable header filter definitions (`filters`). A filter can be referenced either as default for all routes (via `spec.headerFilter.defaultFilterRef`) or for a specific route (via `spec.routes[].headerFilterRef`), in which case its settings are merged with the default:

```yaml
spec:
  headerFilter:
    defaultFilterRef: my-default
    filters:
      - name: my-default
        logOnly: false
        request:
          allowClass: STANDARD
      - name: my-api
        request:
          allow:
            - X-Myapp-1
  routes:
    - match:
        path: /api
        pathType: PREFIX
      headerFilterRef: my-api
      backend:
        # ...
```

> &#128270; If neither a default filter nor a per-route filter is referenced (as in this scenario), request headers are filtered using the `STANDARD` list and response headers are filtered using the default set of allowed response headers.

Each filter allows setting the operation mode using the `logOnly` attribute (defaults to false). When set to `true`, header filtering will only log headers that would be removed but will not alter the transaction (permissive mode), which can be helpful when protecting new applications evaluating possible additional headers being required.

The request and / or response header filtering can be configured independently (via `request` and `response` of a filter), being active in its default configuration for both request and response headers.

### Request header filtering

There are three predefined lists of allowed request headers available to choose from via `request.allowClass` (each one being a superset of the previous one):

* RESTRICTED
* STANDARD
* EXTENDED

By default, the STANDARD list is applied. Using RESTRICTED one can choose to further restrict request headers, while EXTENDED additionally allows client hints and other modern browser/SPA/mobile request headers (see the [allow classes](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/header-filtering/#allow-classes) for the headers contained in each list).

**What if a custom request header is required but filtered by any of the predefined lists?**

In this case you can maintain a list of custom allowed request headers using `request.allow`.

> &#128270; If you had configured the previously seen `x-middleware-subrequest` which enables bypassing Next.js middleware authorization code in specific versions, you should consider removing it (please refer to the [blog post from JFrog](https://jfrog.com/blog/cve-2025-29927-next-js-authorization-bypass/)).

Similarly, you can configure a list of header names to **always deny** using `request.deny` (also when present in the configured `allowClass`), resulting in an effective list of allowed headers being `allowClass` + `allow` - `deny`.

Additionally a list of [deny patterns](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/crd-doc/#corewaapservicespecheaderfilterfiltersindexrequestdenypatternsindex) (`request.denyPatterns`) allows to remove headers whose value matches a regex pattern, either for a specific header name or for all headers (using `*` as name).

To completely disable request header filtering, set `request.enabled` to `false` in which case no request header inspection will be executed (this is different from `logOnly` where inspection is executed but no modifications are made!).

### Response header filtering

Response header filtering will use a predefined implicit list of allowed response headers, being the reason why there is no `response.allowClass` available.

In response header filtering, you can configure custom allowed response headers using `response.allow`, headers to **always deny** using `response.deny` (also when present in the implicit list) and [deny patterns](https://docs.united-security-providers.ch/usp-core-waap/2.1.x/configuration/crd-doc/#corewaapservicespecheaderfilterfiltersindexresponsedenypatternsindex) using `response.denyPatterns`.

To completely disable response header filtering, set `response.enabled` to `false`, in which case no response header inspection will be executed (this is different from `logOnly` where inspection is executed but no modifications are made!).
