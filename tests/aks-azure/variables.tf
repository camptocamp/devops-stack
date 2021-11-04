variable "repo_url" {
  type    = string
  default = "https://github.com/camptocamp/devops-stack.git"
}

variable "base_domain" {
  type    = string
  default = "my.devopsstack.com"
}

variable "location" {
  type    = string
  default = "France Central"
}

variable "target_revision" {
  type    = string
  default = "master"
}

variable "cluster_name" {
  type    = string
  default = "devops-stack-test"
}

variable "public_ssh_file" {
  type = string
}

variable "resource_group" {
  type    = string
  default = "default"
}
