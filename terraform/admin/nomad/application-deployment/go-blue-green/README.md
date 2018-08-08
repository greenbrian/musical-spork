# Golang app example: (Fabio and blue-greens)


Ensure Fabio is Running (It should be already)
```bash
#should be ec2-user or ubuntu user
nomad run /home/$(whoami)/nomad/fabio-${local_region}.nomad
```

Run the job
```bash
$ nomad run go-app.nomad
```

Check the webpage using fabio
```bash
http://ak-hs-9a0ff0bb-fabio-4220c9210d8e0876.elb.us-east-1.amazonaws.com:9999/go-app
```
You should see "is golang 1.9 out yet?". Now make the following change to the go-app.nomad file
```bash
image = "aklaas2/go-app-1.0"
#to
image = "aklaas2/go-app-2.0"
```
See a nomad plan. Notice the new canaries. (blue-green).
```bash
$ nomad plan go-app.nomad
+/- Job: "go-app"
+/- Task Group: "go-app" (3 canary, 3 ignore)
  +/- Task: "go-app" (forces create/destroy update)
    +/- Config {
      +/- image:             "aklaas2/go-app-1.0" => "aklaas2/go-app-2.0"
          port_map[0][http]: "8080"
        }

Scheduler dry-run:
- All tasks successfully allocated.
```
Run the job
```bash
$ nomad run go-app.nomad

$ nomad status go-app
ID            = go-app
Name          = go-app
Submit Date   = 2018-08-07T19:42:19Z
Type          = service
Priority      = 50
Datacenters   = us-east-1
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
go-app      0       1         5        0       3         0

Latest Deployment
ID          = 229a9a42
Status      = running
Description = Deployment is running but requires promotion

Deployed
Task Group  Promoted  Desired  Canaries  Placed  Healthy  Unhealthy  Progress Deadline
go-app      false     3        3         3       0        0          2018-08-07T19:52:56Z

Allocations
ID        Node ID   Task Group  Version  Desired  Status    Created    Modified
954014c9  8dd81311  go-app      3        run      running   11s ago    6s ago
a0829d62  0bf96ebd  go-app      3        run      running   11s ago    8s ago
efd77c1c  0bf96ebd  go-app      3        run      running   11s ago    8s ago
91f93f89  0bf96ebd  go-app      2        run      running   5m53s ago  4m10s ago
07a5b633  02a0dc94  go-app      2        run      pending   5m53s ago  1m17s ago
393fbb4b  8dd81311  go-app      2        run      running   5m53s ago  5m32s ag
```
Notice 6 allocations (3 old, 3 new) are running. Now finish the deployment.

```bash
$ nomad deployment promote 229a9a42
```

The new app should be running. Check fabio.
```bash
http://ak-hs-9a0ff0bb-fabio-4220c9210d8e0876.elb.us-east-1.amazonaws.com:9999/go-app
```
"Is golang 2.0 out yet?"



