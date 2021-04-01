variable "app_name" {
  default = "fargater"
}

variable "env" {
  default = "dev"
}

variable "region" {
  default = "eu-central-1"
}

variable "environment" {
  default = [
    {
      name: "FOO"
      value: "BAR"
    }
  ]
}

variable "command" {
  default = ["ls", "-la", "/"]
}