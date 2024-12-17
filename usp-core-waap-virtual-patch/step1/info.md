&#127919; In this step you will access a problematic prometheus endpoint

### Access Juice Shop profile page

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

The [prometheus]({{TRAFFIC_HOST1_9090}}) application has been setup and will be used to demonstrate a problematic access.

> &#128270; Initially the backend will be accessed unprotected (not using USP Core WAAP)

Try to access the [pprof debug page]({{TRAFFIC_HOST1_9090}}/debug/pprof) which seems to have an issue...

> &#10071; Make sure to have accessed the debug page otherwise the validation in this step will fail...

As outlined in a [prometheus vulnerability analysis](https://www.aquasec.com/blog/300000-prometheus-servers-and-exporters-exposed-to-dos-attacks/) by the Aqua Security team in December 2024, the widely used [prometheus](https://github.com/prometheus/prometheus) application suffers a [DoS](https://en.wikipedia.org/wiki/Denial-of-service_attack) vulnerability through the mentioned endpoint above. Being one part of the vulnerability analysis there are more issues present which we will not further tackle in here.



Now let's see how you can use [virtual patching](https://united-security-providers.github.io/crs-virtual-patch/) **provided by USP Core WAAP** in the next step!
