job "docs" {
  datacenters = ["us-east-1a","us-east-1b","us-east-1c"]
  group "example" {
    task "server" {
      driver = "exec"

      config {
        command = "/bin/http-echo"
        args = [
          "-listen", ":5678",
          "-text", "hello world",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {
            static = "5678"
          }
        }
      }
    }
  }
}
