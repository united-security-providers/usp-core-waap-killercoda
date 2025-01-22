### Introduction

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. USP Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection and [OpenAPI schema validation](https://openapis.org).

This scenario shows how to protect an API endpoint having an OpenAPI specification for using the [USP Core WAAP OpenAPI validation](https://united-security-providers.github.io/usp-core-waap/openapi-validation/) feature.

[OpenAPI specification](https://swagger.io/docs/specification/v3_0/about/) is an API description for REST APIs and allows to describe (or more specifically define) your application API. To learn more about the OpenAPI specification head over to the [documentation](https://swagger.io/docs/specification/v3_0/basic-structure/).

> &#128270; In this scenario the [swagger petstore API](https://petstore.swagger.io/) demo application is used as a backend.

**Now, let's protect that API!**

### Conventions

Throughout the scenario the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
