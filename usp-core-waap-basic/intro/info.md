### Protect the web application

The [OWASP Juiceshop](https://owasp.org/www-project-juice-shop/) encompasses vulnerabilities from the entire [OWASP Top Ten](https://owasp.org/www-project-top-ten/) along with many other security flaws found in real-world application.

**USP Core WAAP** serves as a crucial building block in a defense in depth strategy and mitigates the risk of exposing such severe vulnerabilities. It acts as a reverse proxy in a Kubernetes cluster in front of the target web application. Core WAAP is a web application firewall with a broad security feature set utilizing positive and negative security policies such as [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules, request/response header filtering, cross site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) protection and more security features to come!

>In this scenario  we will use the basic core-rule-set protection preventing SQL-injections on the OWASP Juicehop web application.

**Now, let's protect that app!**
