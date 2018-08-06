job "haproxy-connect-proxy" {
  datacenters = ["us-east-1"]
  type = "service"
  update {
    stagger = "10s"
    max_parallel = 1
  }
  group "haproxy-connect-proxy" {
    count = 3
    restart {
      interval = "5m"
      attempts = 10
      delay = "25s"
      mode = "delay"
    }
    task "proxy" {
      driver = "raw_exec"

      config {
        command = "/usr/local/bin/consul"
        args    = [
          "connect", "proxy",
          "-service", "web",
          "-upstream", "goapp:20000",
          ]
        }
        resources {
          network {
          port "tcp" {
            static=20000
          }
        }
      }
    }
  }
}