### secure the web application

as seen in the [previous juiceshop scenario](../juiceshop) that web application is not that safe...so let's secure the insecure web application!

one way of doing this is going through all the webapplication source code and fix every single vulnerability but this is time consuming and difficult (as you need to know a low about secure coding)...

**what if there was some security guard which protect's that web application?**

well there is one we've heard of!

it's called **USP Core Waap** and acts as a [reverse-proxy](https://en.wikipedia.org/wiki/Reverse_proxy) providing web application firewall (WAF by using [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) rules), request/response header filtering, cross site request forgery ([CSRF](https://owasp.org/www-community/attacks/csrf)) and more security features to come!

>in this scenario here we will use the basic core-rule-set protection preventing SQL-injections on the OWASP Juicehop web application

**now, let's secure that app!**
