variable "path" {
  type = string
  default = "/"
  validation {
    condition = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "path must starts and ends with slash(/)"
  }
}
variable "name" {
  type = string
}
variable "description" {
  type = string
  default = ""
}

variable "statements" {
  type = list(object({
    actions = list(string)
    resources = list(string)
  }))
}