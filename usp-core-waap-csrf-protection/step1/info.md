&#127919; In this step you will:

* Log in to the vulnerable "Juiceshop" application
* Set a username in the profile page

### Access Juice Shop profile page

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

The [OWASP Juice Shop]({{TRAFFIC_HOST1_8080}}/#/login) demo web application has been setup and will be used to demonstrate the 
CSRF Policy feature. Open the application in a new browser tab.

> &#128270; Initially the backend will be accessed unprotected (not using USP Core WAAP)

A demo user "`user@acme.com`" has been pre-configured in the Juiceshop web application.
Log in with the following credentials:

* Username: `user@acme.com`
* Password: `123456`

### Set custom "Username"

Access the [profile page]({{TRAFFIC_HOST1_8080}}/profile) and fill in `DemoUser` in the empty "Username" field.
Click `Set Username` to save the name. 

If you reload the page, you should still see this value as the username.

The next step will show you how this username value can be changed by a web page that is
not part of the Juiceshop application, using cross-site request forgery.

> &#10071; Make sure to have accessed the profile page and set a username.
