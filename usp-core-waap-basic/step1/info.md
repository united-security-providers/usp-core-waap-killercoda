### Login as juiceshop admin

>wait until the console on the right side is ready before trying to access the webapplication (otherwise you'll get a HTTP 502 response)!

[Access the unprotected juiceshop]({{TRAFFIC_HOST1_80}}) web application using your browser and execute an SQL-injection by logging in with:

* email `' OR true;` and
* password `fail` (or anything else except empty)

and see if you succeed...
