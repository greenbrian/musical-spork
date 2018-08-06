# Golang app example: Part 1 (dynamic routing), Part 2 (blue-green upgrade)
This guide will cover two examples. Part 1 will cover a dynamic routing example using Fabio and a Golang Docker app. Part 2 will cover a blue-green upgrade of that app.

### TLDR;
```bash
##PART 1
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run /vagrant/application-deployment/fabio/fabio.nomad

#containers takes a minute or two to download and start
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad

#in your browser go to 
http://localhost:9998/routes

#in your browser go to "golang 1.9 out yet?"
http://localhost:9999/go-app/

##PART 2
#Make the following change to the go-app.nomad image
image = "aklaas2/go-app-1.0"
#to
image = "aklaas2/go-app-2.0"

#See canaries
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad plan go-app.nomad

vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad

#There should be 6 allocs now (three old image)(three new image)
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app

#Grab Deployment ID from "nomad status go-app"
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad deployment promote 562b9ba3

#Back to only 3 allocs with the new image
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app

#in your browser see upgraded app "golang 2.0 out yet?"
http://localhost:9999/go-app/
