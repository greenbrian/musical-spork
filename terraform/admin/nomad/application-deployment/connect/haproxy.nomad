job "haproxy" {
  datacenters = ["us-east-1a","us-east-1b","us-east-1c"]
  type = "service"
  update { stagger = "10s"
    max_parallel = 1
  }
  group "lb" {
    count = 3
    restart {
      interval = "5m"
      attempts = 10
      delay = "25s"
      mode = "delay"
    }
    task "haproxy" {
      driver = "docker"
      config {
        image = "haproxy"
        network_mode = "host"
        port_map {
          http = 80
        }
        volumes = [
          "custom/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg"
        ]
      }
      template {
        #source = "haproxy.cfg.tpl"
        data = <<EOH
        global
          debug
        defaults
          log global
          mode http
          option httplog
          option dontlognull
          timeout connect 5000
          timeout client 50000
          timeout server 50000
        frontend http_front
          bind *:80
          stats uri /haproxy?stats
          default_backend http_back
        backend http_back
          balance roundrobin
          server connect-proxy 127.0.0.1:20000
        EOH

        destination = "custom/haproxy.cfg"
      }
      service {
        name = "haproxy"
        tags = [ "global", "lb", "urlprefix-/haproxy" ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
      resources {
        cpu = 500 # 500 Mhz
        memory = 128 # 128MB
        network {
          mbits = 10
          port "http" {
            static = 80
          }
        }
      }
    }
#    task "proxy" {
#      driver = "raw_exec"

#      config {
#        command = "/usr/local/bin/consul"
#        args    = [
#          "connect", "proxy",
#          "-service", "web",
#          "-upstream", "goapp:${NOMAD_PORT_tcp}",
#          ]
#        }
#        resources {
#          network {
#          port "tcp" {
#            static=8082
#          }
#        }
#      }
#    }
  }
}
