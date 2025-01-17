### Introduction

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. USP Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection and [OpenAPI schema validation](https://openapis.org).

This scenario shows how **virtual patching** can mitigate an application vulnerability prior to applying the application fix itself. To get more background about `virtual patching` read the [Virtual Patching Best Practices](https://owasp.org/www-community/Virtual_Patching_Best_Practices) by [OWASP](https://owasp.org/).

> &#128270; In this scenario the [prometheus](https://github.com/prometheus/prometheus) application is used as a backend.

**Now, let's get started!**

### Conventions

Throughout the scenario the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
