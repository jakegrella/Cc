variable "bucket_prefix" {
  description = "prefix to name of storage bucket"
  type        = string
  default     = "test-"
}

variable "neon_project_name" {
  description = "name of project for neon"
  type        = string
  default     = "test"
}
