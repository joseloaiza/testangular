variable "health_check" {
   type = map(string)
   default = {
      "timeout"  = "5"
      "interval" = "10"
      "path"     = "/stat"
      "port"     = "80"
      "unhealthy_threshold" = "2"
      "healthy_threshold" = "3"
    }
}