job "fabio" {
    region = "us-west-2"
    datacenters = ["us-west-2a"]
    type = "system"
    update {
        stagger = "5s"
        max_parallel = 1
    }
    group "fabio" {
        task "fabio" {
            driver = "exec"
            config {
                command = "fabio"
            }
            artifact {
                source = "https://github.com/fabiolb/fabio/releases/download/v1.5.3/fabio-1.5.3-go1.9.2-linux_amd64"
                destination = "local/fabio"
                mode = "file"
            }
            resources {
                cpu = 500
                memory = 64
                network {
                    mbits = 1

                    port "http" {
                        static = 9999
                    }
                    port "ui" {
                        static = 9998
                    }
                }
            }
            service {
                tags = ["http"]
                name = "fabio"
                port = "http"
            }
            service {
                tags = ["ui"]
                name = "fabio"
                port = "ui"
            }
        }
    }
}
