### Introduction

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. USP Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection and [OpenAPI schema validation](https://openapis.org).

> &#8987; Make sure to checkout the [manual configuration tuning scenario](../usp-core-waap-fp-intro) first prior to this one!

This scenario shows how to tackle **false positives** as a next step to the [manual configuration tuning scenario](../usp-core-waap-fp-intro) using the [auto-learning feature](https://docs.united-security-providers.ch/usp-core-waap/autolearning/).

> &#128270; In this scenario the [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) demo web application is used as a backend.

**Now, let's get started!**

### Conventions

Throughout the scenario the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
