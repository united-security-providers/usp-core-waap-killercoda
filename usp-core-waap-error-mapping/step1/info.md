&#127919; In this step you will access Juice Shop profile page triggering an application error

### Access Juice Shop profile page

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

The [OWASP Juice Shop]({{TRAFFIC_HOST1_8080}}) demo web application has been setup and will be used to demonstrate the custom error pages feature.

> &#128270; Initially the backend will be accessed unprotected (not using USP Core WAAP)

Try to access the [profile page]({{TRAFFIC_HOST1_8080}}/profile) which seems to have an issue...
(caused by the fact you are not logged in yet)

> &#10071; Make sure to have accessed the profile page (while not being logged in) otherwise the validation in this step will fail...

As you can see, a lot of background information (source code filenames and component versions) is given to the user unintentionally.

> &#128270; The behavior of the profile page is a bug in the backend application. The application should redirect you to the login page if you are not logged in yet. USP Core WAAP can protect you from exposing such an improper error handling to the user.

Now let's see how you can use [Error Pages / Static Files](https://united-security-providers.github.io/usp-core-waap/error-pages-static-files/) **provided by USP Core WAAP** in the next steps!
