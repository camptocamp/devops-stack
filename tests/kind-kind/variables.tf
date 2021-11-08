variable "repo_url" {
  type    = string
  default = "https://github.com/camptocamp/devops-stack.git"
}

variable "target_revision" {
  type    = string
  default = "master"
}

variable "cluster_name" {
  type    = string
  default = "default"
}

variable "api_server_address" {
  type    = string
  default = "127.0.0.1"
}
