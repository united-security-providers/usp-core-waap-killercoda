<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

### Introduction

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. USP Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection and [OpenAPI schema validation](https://openapis.org).

This scenario shows the usage of [custom error pages](https://docs.united-security-providers.ch/usp-core-waap/error-mapping/) to improve error handling and prevent information leakage.

> &#128270; In this scenario the [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) demo web application is used as a backend.

**Now, let's explore custom error pages!**

### Conventions

Throughout the scenario the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
