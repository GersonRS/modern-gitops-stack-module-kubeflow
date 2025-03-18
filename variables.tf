#######################
## Standard variables
#######################

variable "project_source_repo" {
  description = "Repository allowed to be scraped in this AppProject."
  type        = string
  default     = "https://github.com/GersonRS/modern-gitops-stack-module-kubeflow.git"
}

variable "namespace" {
  description = "Namespace where the applications's Kubernetes resources should be created. Namespace will be created in case it doesn't exist."
  type        = string
  default     = "kubeflow"
}

variable "argocd_namespace" {
  description = "Namespace used by Argo CD where the Application and AppProject resources should be created."
  type        = string
  default     = "argocd"
}

variable "cluster_name" {
  description = "Name given to the cluster. Value used for naming some the resources created by the module."
  type        = string
}

variable "base_domain" {
  description = "Base domain of the cluster. Value used for the ingress' URL of the application."
  type        = string
}

variable "subdomain" {
  description = "Subdomain of the cluster. Value used for the ingress' URL of the application."
  type        = string
  default     = "apps"
  nullable    = false
}

variable "argocd_project" {
  description = "Name of the Argo CD AppProject where the Application should be created. If not set, the Application will be created in a new AppProject only for this Application."
  type        = string
  default     = null
}

variable "argocd_labels" {
  description = "Labels to attach to the Argo CD Application resource."
  type        = map(string)
  default     = {}
}

variable "destination_cluster" {
  description = "Destination cluster where the application should be deployed."
  type        = string
  default     = "in-cluster"
}

variable "target_revision" {
  description = "Override of target revision of the application chart."
  type        = string
  default     = "v2.5.0" # x-release-please-version
}

variable "cluster_issuer" {
  description = "SSL certificate issuer to use. Usually you would configure this value as `letsencrypt-staging` or `letsencrypt-prod` on your root `*.tf` files."
  type        = string
  default     = "selfsigned-issuer"
}

variable "helm_values" {
  description = "Helm chart value overrides. They should be passed as a list of HCL structures."
  type        = any
  default     = []
}

variable "deep_merge_append_list" {
  description = "A boolean flag to enable/disable appending lists instead of overwriting them."
  type        = bool
  default     = false
}

variable "app_autosync" {
  description = "Automated sync options for the Argo CD Application resource."
  type = object({
    allow_empty = optional(bool)
    prune       = optional(bool)
    self_heal   = optional(bool)
  })
  default = {
    allow_empty = false
    prune       = true
    self_heal   = true
  }
}

variable "dependency_ids" {
  type    = map(string)
  default = {}
}

#######################
## Module variables
#######################

variable "resources" {
  description = <<-EOT
    Resource limits and requests for kube-prometheus-stack's components. Follow the style on https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/[official documentation] to understand the format of the values.

    IMPORTANT: These are not production values. You should always adjust them to your needs.
  EOT
  type = object({

    prometheus = optional(object({
      requests = optional(object({
        cpu    = optional(string, "250m")
        memory = optional(string, "512Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "1024Mi")
      }), {})
    }), {})

    prometheus_operator = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "128Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "128Mi")
      }), {})
    }), {})

    thanos_sidecar = optional(object({
      requests = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "256Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "512Mi")
      }), {})
    }), {})

    alertmanager = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "128Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "256Mi")
      }), {})
    }), {})

    kube_state_metrics = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "128Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "128Mi")
      }), {})
    }), {})

    grafana = optional(object({
      requests = optional(object({
        cpu    = optional(string, "250m")
        memory = optional(string, "512Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "512Mi")
      }), {})
    }), {})

    node_exporter = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "128Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string, "128Mi")
      }), {})
    }), {})

  })
  default = {}
}
