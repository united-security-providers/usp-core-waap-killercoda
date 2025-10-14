<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Learn more about header filtering configuration

As seen by this demo here, the default configuration of USP Core WAAP header filtering protects by the fact that unlisted request and response headers are removed. In this last step we will dive into the configuration options available to customize the header filtering feature if needed.

### Header filtering configuration

> &#128270; Refer to the [header filtering documentation](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespecheaderfilteringrequest) for a complete list of available configuration options.

By inspecting the list of headers against a list of predefined headers and custom allowed / denied headers, the feature will remove headers accordingly.

The feature is configured within the USP Core WAAP Kubernetes resource CoreWaapService via `spec.headerFiltering` attribute, which allows setting the operation mode of the feature using the `logOnly` attribute (defaults to false). When set to `true`, header filtering will only log headers that would be removed but will not alter the transaction (permissive mode), which can be helpful when protecting new applications evaluating possible additional headers being required.

The request and / or response header filtering can be configured independently, being active in its default configuration for both request and response headers.

### Request header filtering

There are three predefined lists of allowed request headers available to choose from via `spec.headerFiltering.request.allowClass`:

* STANDARD
* RESTRICTED
* MINIMAL

By default, the STANDARD list is applied, being the least restrictive one, and using RESTRICTED or even MINIMAL, one can choose to further restrict request headers filtering.

**What if a custom request header is required but filtered by any of the predefined lists?**

In this case you can maintain a list of custom allowed request headers using `spec.headerFiltering.request.allow`.

> &#128270; If you had configured the previously seen `x-middleware-subrequest` which enables bypassing Next.js middleware authorization code in specific versions, you should consider removing it (please refer to the [blog post from JFrog](https://jfrog.com/blog/cve-2025-29927-next-js-authorization-bypass/)).

Similarly to customize the allowed request headers, you can also configure a list of [deny patterns](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespecheaderfilteringrequestdenyindex) to **always deny request headers** matching that pattern (also when configured in `allow` or present in the configured `allowClass`).

To completely disable request header filtering, set `spec.headerFiltering.request.enabled` to `false` in which case no request header inspection will be executed (this is different from `logOnly` where inspection is executed but no modifications are made!).

### Response header filtering

Response header filtering will use a predefined `STANDARD` list, being the only one available, being the reason why there is no `spec.headerFiltering.response.allowClass` available.

In response header filtering, you can configure custom allowed response headers using `spec.headerFiltering.response.allow` attribute and a list of [deny headers](https://docs.united-security-providers.ch/usp-core-waap/latest/crd-doc/#corewaapservicespecheaderfilteringresponse) to **always deny** matching that name (also when configured in `allow` or the default internal used `STANDARD` list).

To completely disable request header filtering, set `spec.headerFiltering.response.enabled` to `false`, in which case no request header inspection will be executed (this is different from `logOnly` where inspection is executed but no modifications are made!).
