&#127919; In this step you will:

* Attempt a CSRF injection using the "evil" attacker website
* The attack will change the "Username" value in the Juiceshop user profile

### Access attacker website page

The [Attacker Website]({{TRAFFIC_HOST1_9090}}/direct.html) web application has been setup and will be used to demonstrate the
CSRF attack. Open the application in a new browser tab.

A simple HTML page is shown with an input form field and a submit button. By clicking the button, 
a POST request will be sent from this page to the URL entered in the input field, 
attempting to change the "Username" value in the user profile.

### Hack "Username"

* Click the "Hack Username" button

This will send the "evil" request to the Juiceshop and change the "Username". You will receive a response 
from the Juiceshop - the profile page, with the username changed to *"hacked"*.

In the other tab, where you opened the Juiceshop app, reload the profile page - you will also see
the changed "Username" value.

The reason why this is possible is that the "evil" page was running in the same browser where you are logged in into
the Juiceshop. The browser automatically sends all the session cookies to the Juiceshop backend with every request,
even if the request was made by a page that was not actually part of the Juiceshop. In other words, the attackers web page
"injected" itself into the open, authenticated session, and used it to change user information without the Juiceshop
application being aware of it.

> &#10071; Close the Juiceshop and the attacker browser tabs and continue with the next step.