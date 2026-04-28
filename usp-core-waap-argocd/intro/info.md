<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

### Introduction

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. USP Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross-site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection, [OpenAPI schema validation](https://openapis.org) and extended [GraphQL schema validation](https://graphql.org/learn/validation/) and protection.

This scenario shows the usage of **DevOps like** management of one (or multiple) Core WAAP instances. To get more background about USP Core WAAP head over to the [documentation](https://docs.united-security-providers.ch/usp-core-waap/latest/).

> &#128270; In this scenario the [Argo CD](https://argo-cd.readthedocs.io/) and [Gogs](https://gogs.io/) applications are used in addition to the famous [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) acting as a web application backend.

**Now, let's get started!**

### Conventions

Throughout the scenario, the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
