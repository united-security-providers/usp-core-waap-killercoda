<!--
SPDX-FileCopyrightText: 2026 United Security Providers AG, Switzerland

SPDX-License-Identifier: GPL-3.0-only
-->

&#127919; In this step you will:

* Modify the Core WAAP configuration
* Observe configuration update via ArgoCD

From the previous step here the information how to access ArgoCD / Gogs WebUIs:

* Link: [Gogs application]({{TRAFFIC_HOST1_30080}}/user/login?redirect_to=)
  * Username: `gituser`
  * Password: `gitpassword`
* Link: [ArgoCD application]({{TRAFFIC_HOST1_30081}})
  * Username: `admin`
  * Get initial Password using command below

```shell
argocd admin initial-password -n argocd
```{{exec}}

### Modify the Core WAAP configuration

The configuration in use by ArgoCD is placed in the folder named `repodata` and there an application folder `juiceshop` provides an application YAML file for the OWASP Juiceshop backend (`app.yaml`) and the USP Core WAAP instance (`waap.yaml`). The files are part of a git repository already setup for you.

Let's have a look at these files:

```shell
cd ~/repodata
git status
cat juiceshop/waap.yaml
```{{exec}}

<details>
<summary>example command output</summary>

```shell
root@controlplane:~$ cd ~/repodata/
root@controlplane:~/repodata$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
root@controlplane:~/repodata$ cat juiceshop/waap.yaml
---
apiVersion: waap.core.u-s-p.ch/v1alpha1
kind: CoreWaapService
metadata:
  name: juiceshop-usp-core-waap
spec:
  coraza:
    crs:
      paranoiaLevel: 2
  routes:
    - match:
        path: "/"
        pathType: "PREFIX"
      backend:
        address: juiceshop
        port: 8080
        protocol:
          selection: h1
```

</details>
<br />

> &#128270; If we modify the `juiceshop/waap.yaml` file (being the Core WAAP Instance config) add the changes to the repository (git add / git commit / git push or using the [Gogs webUI]({{TRAFFIC_HOST1_30080}}/gituser/testrepo/)) ArgoCD will modify the Resources in Kubernetes accordingly.

Now lets make a manual change to the Core WAAP resource as well by changing the paranoiaLevel from 2 to 3. First we change the actual configuration after making sure our local configuration file is up2date:

```shell
cd ~/repodata
git pull
sed -i 's/paranoiaLevel:.*/paranoiaLevel: 3/' juiceshop/waap.yaml
git add juiceshop/waap.yaml
git commit -m 'set to PL:3'
git push
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Already up to date.
[main 03d20d9] set to PL:3
 1 file changed, 1 insertion(+), 1 deletion(-)
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (4/4), 346 bytes | 346.00 KiB/s, done.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0
To http://172.30.2.2:30080/gituser/testrepo.git
   31656a6..03d20d9  main -> main
```

</details>
<br />

You can extract what `paranoiaLevel` is in use by

```shell
kubectl \
  get corewaapservices.waap.core.u-s-p.ch/juiceshop-usp-core-waap \
  -n juiceshop \
  -o json \
  | jq -r '.spec.coraza.crs.paranoiaLevel'
```{{exec}}

> &#10071; Make sure to have updated the Core WAAP configuration by this step otherwise the validation will fail!

The [USP Core WAAP Auto-Learning Tool](https://docs.united-security-providers.ch/usp-core-waap/latest/downloads/) has been downloaded to your home folder and can be accessed using

```shell
java -jar ~/corewaap-autolearn-cli.jar
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Error: Missing required argument (specify one of these): ([-i=<specIn> -l=<log>] | [-n=<namespace> -w=<instance>])
Usage: java -jar waap-lib-autolearn-cli-<version>.jar [-hV] ([-i=<specIn>
       -l=<log>] | [-n=<namespace> -w=<instance>]) [[-o=<specOut>]] [[crs]
       [graphql] [methods]] [[-t=<range>] [-e=<errorFile>] [-s]]
       [[--skippostparts] [--skipmetadataexport] [--sortexceptions]
       [--reduceconfigured]]
Autolearns CRS rule exceptions and methods whitelisting from USP Core WAAP log
files.
Copyright (c) United Security Providers AG, Switzerland, All rights reserved.
  -h, --help                 Show this help message and exit.
  -V, --version              Print version information and exit.
file input
  -i, --waapspecin=<specIn>  USP Core WAAP spec file (or manifest file) to
                               read, use '-' for stdin, exclusive with -n/-w.
  -l, --log=<log>            USP Core WAAP log file to parse, exclusive with
                               -n/-w.
k8s instance input
  -n, --namespace=<namespace>
                             Kubernetes namespace with USP Core WAAP, exclusive
                               with -i/-l.
  -w, --waapinstance=<instance>
                             Kubernetes USP Core WAAP instance name (app.
                               kubernetes.io/instance), exclusive with -i/-l.
output
  -o, --waapspecout=<specOut>
                             USP Core WAAP spec file (or manifest file) to
                               write, defaults to 'waap.yaml', use '-' for
                               stdout (then automatically also -s).
processors
      crs                    Autolearns CRS rule exceptions
      graphql                Autolearns max. values for GraphQL queries
      methods                Autolearns HTTP methods whitelisting
common options
  -e, --errorfile=<errorFile>
                             File to write errors to, optional, by default no
                               file is written.
  -s, --silent               No output to stdout with number of learned rules
                               and errors.
  -t, --timerange=<range>    Optional time range to learn from, e.g.
                               "20231201.1010-20231202.1010" (time with
                               minutes).
CRS mode options
      --reduceconfigured     Changes already configured exceptions by removing
                               a) duplicates & b) more specific rules in favor
                               of more general ones
      --skipmetadataexport   Skip metadata export.
      --skippostparts        Skip part name parsing for ARGS_POST.
      --sortexceptions       Sort rule exceptions in the output.
root@controlplane:~$
```

</details>
<br />

By executing the **USP Core WAAP Auto-Learning Tool** it can parse a running Core WAAP Instance and propose rule exceptions based on rule hits observed.

We start off by initially accepting the current rule hits if any (before we accessed the Juiceshop for a first time yet) and will later see how an automated process can repeatedly provide code pull request to be reviewed by security personnel.

```shell
java -jar ~/corewaap-autolearn-cli.jar \
  -n juiceshop \
  -w juiceshop-usp-core-waap \
  -o ~/repodata/juiceshop/waap.yaml \
  crs \
  --reduceconfigured \
  --sortexceptions
```{{exec}}

Explanation of command cli options used:

* `-n juiceshop` : by this we instruct the tool to look into the Kubernetes Namespace `juiceshop`
* `-w juiceshop-usp-core-waap` : here we instruct the tool to look for the instance with this name
* `-o ~/repodata/juiceshop/waap.yaml` : we write the new instance configuration to our existing code repository
* `crs` : we use the mode CRS
* `--reduceconfigured` : we want to have optimized config output (if possible merge exceptions)
* `--sortexceptions` : to have a consistent output we sort the exception (better pull request readability)

<details>
<summary>example command output</summary>

```shell
Learned request/response rule exceptions: 0/0.
```

</details>
<br />

After this step the local `waap.yaml` configuration has been modified by the USP Core WAAP Auto-Learning Tool for you to be pushed to the repository:

```shell
cd ~/repodata
git pull
git add juiceshop/waap.yaml
git commit -m 'initial manual auto-learning state'
git push
```{{exec}}

<details>
<summary>example command output</summary>

```shell
Already up to date.
[main 4c935b9] initial manual auto-learning state
 1 file changed, 62 insertions(+), 13 deletions(-)
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (4/4), 1.13 KiB | 1.13 MiB/s, done.
Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
To http://172.30.2.2:30080/gituser/testrepo.git
   03d20d9..4c935b9  main -> main
```

</details>
<br />

### Observe configuration update via ArgoCD

Have a look at the [ArgoCD application]({{TRAFFIC_HOST1_30081}}) to see changes from the code repository being applied (it might take up to 3 minutes for ArgoCD to recognize the change).

In the next step we will have a look on how to automate this manual step of adding rule exceptions.
