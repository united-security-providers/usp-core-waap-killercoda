<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will access a problematic prometheus endpoint

### Access prometheus debug endpoint page

> &#8987; Wait until the console on the right side shows `*** Scenario ready ***` before accessing the backend (otherwise you'll see a `HTTP 502 Bad Gateway` error)!

As outlined in a [prometheus vulnerability analysis](https://www.aquasec.com/blog/300000-prometheus-servers-and-exporters-exposed-to-dos-attacks/) by the Aqua Security team in December 2024, the widely used [prometheus](https://github.com/prometheus/prometheus) application suffers a [DoS](https://en.wikipedia.org/wiki/Denial-of-service_attack) vulnerability through the mentioned endpoint above. Being one part of the vulnerability analysis there are more issues present which we will not further tackle in here.

The [prometheus application]({{TRAFFIC_HOST1_9090}}) has been setup and will be used to demonstrate the problematic endpoint being accessed at `/debug/pprof`.

> &#128270; Initially the backend will be accessed unprotected (not using USP Core WAAP)

Access the [pprof debug page]({{TRAFFIC_HOST1_9090}}/debug/pprof) which is an issue as this endpoint can be used to trigger a [DoS](https://en.wikipedia.org/wiki/Denial-of-service_attack) event.

Now let's see how you can use [virtual patching](https://docs.united-security-providers.ch/usp-core-waap/crs-virtual-patch/) **provided by USP Core WAAP** in the next step!
