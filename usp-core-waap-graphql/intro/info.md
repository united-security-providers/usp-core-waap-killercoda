<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

### Introduction

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. USP Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross-site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection, [OpenAPI schema validation](https://openapis.org) and extended [GraphQL schema validation](https://graphql.org/learn/validation/) and protection.

This scenario shows the basic usage of **GraphQL filtering**. To get more background about GraphQL filtering, read the [Core WAAP documentation](https://docs.united-security-providers.ch/usp-core-waap/latest/).

> &#128270; In this scenario the [LLDAP application](https://github.com/lldap/lldap) is used as a backend.

**Now, let's get started!**

### Conventions

Throughout the scenario, the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
