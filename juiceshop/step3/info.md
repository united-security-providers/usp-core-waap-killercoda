> Port-forwarding needs to listen on all interfaces (--address 0.0.0.0) !

in order to access the webapplication via its service definition we'll use a kubernetes `port-forward`, go ahead and forward port 80 to the service created...

then [access the application]({{TRAFFIC_HOST1_80}}) using your browser!

now try to login (top right -> account -> login) using the email `' OR true;` and any password (just not empty)...

splendid! you just executed an SQL-injection to a vulnerable web application!
let's see if this could be protected withot having to modify the web application at all (you know secure coding is difficult...)

<details>

<summary>show me the solution</summary>

```shell
kubectl port-forward service/juiceshop 80:80 --address 0.0.0.0
```{{exec}}

</details>
