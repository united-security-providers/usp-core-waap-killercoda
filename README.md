<!--
SPDX-FileCopyrightText: 2025 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

# USP Core WAAP killercoda scenarios

This repository contains the scenarios published via [killercoda](https://killercoda.com/)

## List of scenarios

* usp-core-waap-intro           : entry-level scenario to show-case the Core WAAP using Core Rule Set protection (preventing OWASP Juice Shop SQL-injection)
* usp-core-waap-error-mapping   : scenario to show-case the Core WAAP error pages feature
* usp-core-waap-fp-intro        : scenario to show-case Core WAAP Core Rule Set false-positives manual handling
* usp-core-waap-fp-autolearn    : scenario to show-case Core WAAP Core Rule Set false-positives auto-learning
* usp-core-waap-virtual-patch   : scenario to show-case Core WAAP virtual patching feature
* usp-core-waap-openapi-intro   : scenario to show-case Core WAAP OpenAPI spec validation feature
* usp-core-waap-csrf-protection : scenario to show-case Core WAAP CSRF policy feature

**Keep in mind when renaming directories the killercoda scenario URL will change!**

The order of the scenarios without a `structure.json` will be according the scenario title alphabetically sorted! Use the following command to identify wrong top-level paths inside your `structure.json` file:

```shell
for d in $(jq -r '.items[].path' structure.json);do ls -d $d;done
```

## Core WAAP Artifact access

The Core WAAP project uses three types of artifacts which are

* one Helm chart
* one Operator container image
* one Base and multiple side-car container images

These artifacts are [pushed to different registries](https://wiki.swisscom.com/display/USPWAM/USP+Container+delivery#USPContainerdelivery-ContainerRegistryInfrastructure) where the Azure Dev Registry `devuspregistry.azurecr.io` is to be used for Kilercoda scenarios (otherwise RCs are not available to develop scenarios).

Since access to all these artifacts is restricted (customers use a dedicated access token) there is also one [dedicated access token](https://portal.azure.com/#@usplabsesdev.onmicrosoft.com/resource/subscriptions/2e78d607-0ada-406c-a87d-07cd55718b63/resourceGroups/dev-acr-rg/providers/Microsoft.ContainerRegistry/registries/devuspregistry/token) `killercoda` (using the `corewaap-demo` scope map) giving access to the following repositories:

* helm/usp/core/waap/usp-core-waap-operator : access to the helm chart
* usp/core/waap/demo/* : access to container images (for base Core WAAP as of 2024-Q4 demo image the others selected versions used by killercoda)

|OriginalRepo                                 | DemoRepo                                          | KillercodaAccess | Remarks                                   |
|---------------------------------------------|---------------------------------------------------|------------------|-------------------------------------------|
|helm/usp/core/waap/usp-core-waap-operator    | n/a                                               | OriginalRepo     | no demo artifact wanted                   |
|usp/core/waap/usp-core-waap-operator         | usp/core/waap/demo/usp-core-waap-operator         | DemoRepo         | selected images copied to demo repository (no dedicated demo image avilable yet) |
|usp/core/waap/usp-core-waap                  | usp/core/waap/demo/usp-core-waap-demo             | DemoRepo         | dedicated demo image (image name "-demo") |
|usp/core/waap/usp-core-waap-ext-proc-icap    | usp/core/waap/demo/usp-core-waap-ext-proc-icap    | DemoRepo         | selected images copied to demo repository  (no dedicated demo image avilable yet) |
|usp/core/waap/usp-core-waap-ext-proc-openapi | usp/core/waap/demo/usp-core-waap-ext-proc-openapi | DemoRepo         | selected images copied to demo repository  (no dedicated demo image avilable yet) |
|usp/core/waap/usp-core-waap-ext-proc-...     | usp/core/waap/demo/usp-core-waap-ext-proc-...     | DemoRepo         | selected images copied to demo repository unless dedicated demo image is available |

Note: when copying an image to another repository the storage usage does not change (Azure Container Registry recognizes the same image and links the object only)

The reason to manually copy images from `OriginalRepo` to `DemoRepo` is to control access to images (ACR does not support controlling image access only repository level). By this we also get a "view" on what images are used by public use-case like Killercoda (i.e. Killercoda uses openapi side car version 0.0.3 although 0.0.4 and 0.0.5 are released too).

In order to make a version available in the `DemoRepo` login to the `devuspregistry.azurecr.io` (using `usp-ci-bob` access token granting write access) and

1. pull original artifact
1. tag artifact into demo repository
1. push artifact to the demo repository

in the following example the `usp-core-waap-operator:1.0.1` artifact will be copied to the demo repository for being accessed by Killercoda scenarios:

```shell
docker pull devuspregistry.azurecr.io/usp/core/waap/usp-core-waap-operator:1.0.1
docker tag devuspregistry.azurecr.io/usp/core/waap/demo/usp-core-waap-operator:1.0.1
docker push devuspregistry.azurecr.io/usp/core/waap/demo/usp-core-waap-operator:1.0.1
```

For more information also read internal [Core WAAP build wiki](https://git.u-s-p.local/core-waap/core-waap-build/-/wikis/Core-WAAP-Release-Process/)

## Rules and guidelines

* use the term 'USP Core WAAP' (and not 'Core Waap' - note the uppercase waap)
* in addition also make sure to add an "overview" section at first for every step (not on intro/finish) which outlines what will be covered within this step.
* make sure to include the icon-set overview on the first `intro.text` Element (linked via `index.json`) of the scenario (see below)

**intro icon-set example**
```markdown
Throughout the scenario the following conventions are used:

> &#10071; Important information

> &#128270; Additional details

> &#8987; Wait for a condition prior to continue
```

**step overview example**
```markdown
&#127919; In this step you will:

* Inspect the logs of USP Core WAAP
* Reconfigure the USP Core WAAP instance to ...
* Check the logs to verify false positives are gone
```

and then use headings (level 3) for each mentioned point...

## Scenario development

Read through the [killercoda creator documentation](https://killercoda.com/creators) and check the existing scenario examples at

* [https://github.com/killercoda/scenario-examples.git](https://github.com/killercoda/scenario-examples.git)
* [https://github.com/killercoda/scenario-examples-courses.git](https://github.com/killercoda/scenario-examples-courses.git)

In order to modify [USP killercoda scenarios](https://killercoda.com/united-security-providers) one has to...

1. [create a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) of the "live" repo https://github.com/united-security-providers/usp-core-waap-killercoda (i.e. https://github.com/usp-rol/usp-core-waap-killercoda-dev as rol did)
1. head over to [your killercoda creator profiles](https://killercoda.com/creator/profiles) and select the profile (or create one if there is none)
1. select **repository** option (URL being `https://killercoda.com/creator/repository/$your-profile-name`) and [configure your fork repo](https://killercoda.com/creators/get-started)
1. Repo Name will be **everything after github.com/** from your fork created (i.e. usp-rol/usp-core-waap-killercoda-dev) and configure your branch (usually main)
1. Add deployment key from your [creator repository](https://killercoda.com/creator/repository) to your github fork (settings => Deploy keys)
1. Add Github webhook config from your [creator repository](https://killercoda.com/creator/repository) to your github fork (settings => Webhooks)

Test your killercoda profile https://killercoda.com/$your-profile-name and modify your fork repo by pushing to github (start with a markdown modification for example)

## Release development work

Once you are satisfied with your modifications (probably let them test by another team member) you then can update the "live" repo by **contributing back** via github.com to the upstream repo (consider reading through [github.com documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) if unsure of how to do that).

## Debugging intro scripts

For intro scripts only there are default logs available on the console in

* `/var/log/killercoda/background0_stdout.log`
* `/var/log/killercoda/background0_stderr.log`

or accessible via https://killercoda.com/creator/debug/$your-profile-name

## Known issues

as it seems a background script outside the "intro" section will timeout after 10s and thus end in the UI showing "background script failed".
to mitigate this execute another script not waiting for finishing (and probably use [foreground/background communication](https://github.com/killercoda/scenario-examples/tree/main/foreground-background-scripts-multi-step)):

```shell
#!/bin/bash

# trigger an external script
bash ~/.scenario_staging/long-running-script.sh &
exit 0
```
