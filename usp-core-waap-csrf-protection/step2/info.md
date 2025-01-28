&#127919; In this step you will:

* Attempt a CSRF injection using the "evil" attacker website
* The attack will change the "Username" value in the Juiceshop user profile

### Access attacker website page

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the attacker website (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

The [Attacker Website]({{TRAFFIC_HOST1_9090}}) web application has been setup and will be used to demonstrate the 
CSRF attack. Open the application in a new browser tab.

A simple HTML page is shown with a submit button. By clicking the button, a POST request will be sent from
this page, directly to the Juiceshop backend, and change the "Username" value in the user profile.

### Hack "Username"

* In the "Juiceshop" browser tab, select the URL and copy it
* Change to the attacker website browser tab and paste the Juiceshop URL into the "URL" input field

*Click the "Hack Username" button* - this will send the "evil" request to the Juiceshop and change the "Username". 
You will receive a response from the Juiceshop - the profile page, with the username changed to *"hacked"*.

In the other tab, where you opened the Juiceshop app, reload the profile page - you will also see
the changed "Username" value.

The reason why this is possible is that the "evil" page was running in the same browser where you are logged in into
the Juiceshop. The browser automatically sends all the session cookies to the Juiceshop backend with every request,
even if the request was made by a page that was not actually part of the Juiceshop. In other words, the attackers web page
"injected" itself into the open, authenticated session, and used it to change user information without the Juiceshop
application being aware of it.

> &#10071; Close the Juiceshop and the attacker browser tabs and continue with the next step.