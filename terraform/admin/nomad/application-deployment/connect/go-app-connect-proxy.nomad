job "go-app-connect-proxy" {
  datacenters = ["us-east-1"]
  type = "service"
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 3
  }
  group "go-app-connect-proxy" {
    count = 3
    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"
      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"
      mode = "delay"
    }
    ephemeral_disk {
      size = 300
    }
    task "connect-proxy" {
      driver = "raw_exec"

      config {
          command = "/usr/local/bin/consul"
          args    = [
              "connect", "proxy",
              "-service", "goapp",
              "-service-addr", "${NOMAD_IP_tcp}:8080",
              "-listen", ":20001",
              "-register",
          ]
      }

      resources {
          network {
              port "tcp" {
                  static=20001
              }
          }
      }
    }
  }
}