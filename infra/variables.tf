# Variables = the configuration's knobs. Everything else is fixed; these are
# the values a deployer may legitimately want to change without editing code.

variable "region" {
  description = "AWS region (Frankfurt: closest to the Europe/Berlin audience)"
  type        = string
  default     = "eu-central-1"
}

variable "github_repository" {
  description = "GitHub repo (owner/name) whose main branch may push images"
  type        = string
  default     = "luke-m/trianglobe"
}
