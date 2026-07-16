# Variables = the configuration's knobs. Everything else is fixed; these are
# the values a deployer may legitimately want to change without editing code.

variable "region" {
  description = "AWS region (Frankfurt: closest to the Europe/Berlin audience)"
  type        = string
  default     = "eu-central-1"
}
