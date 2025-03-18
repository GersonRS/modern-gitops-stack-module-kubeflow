resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "argocd_project" "this" {
  count = var.argocd_project == null ? 1 : 0

  metadata {
    name      = var.destination_cluster != "in-cluster" ? "kubeflow-${var.destination_cluster}" : "kubeflow"
    namespace = var.argocd_namespace
  }

  spec {
    description  = "kubeflow application project for cluster ${var.destination_cluster}"
    source_repos = [var.project_source_repo]

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    destination {
      name      = var.destination_cluster
      namespace = "kube-system"
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

data "utils_deep_merge_yaml" "values" {
  input       = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
  append_list = var.deep_merge_append_list
}

resource "argocd_application" "oauth2-proxy" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "oauth2-proxy-${var.destination_cluster}" : "oauth2-proxy"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "oauth2-proxy"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kubeflow/common/oauth2-proxy"
      target_revision = var.target_revision
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
  ]
}

resource "argocd_application" "dex" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "dex-${var.destination_cluster}" : "dex"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "dex"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kubeflow/common/dex-istio"
      target_revision = var.target_revision
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }

  depends_on = [
    resource.argocd_application.oauth2-proxy,
  ]
}

resource "argocd_application" "kubeflow-configs" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "kubeflow-configs-${var.destination_cluster}" : "kubeflow-configs"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "kubeflow-configs"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kubeflow/common/roles-namespaces"
      target_revision = var.target_revision
    }

    ignore_difference {
      group = "rbac.authorization.k8s.io"
      kind  = "ClusterRole"
      jq_path_expressions = [
        ".rules"
      ]
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }

  depends_on = [
    resource.argocd_application.oauth2-proxy,
  ]
}

resource "argocd_application" "central-dashboard" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "central-dashboard-${var.destination_cluster}" : "central-dashboard"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "central-dashboard"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kubeflow/apps/central-dashboard"
      target_revision = var.target_revision
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }

  depends_on = [
    resource.argocd_application.kubeflow-configs,
  ]
}

resource "argocd_application" "admission-webhook" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "admission-webhook-${var.destination_cluster}" : "admission-webhook"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "admission-webhook"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kubeflow/apps/admission-webhook"
      target_revision = var.target_revision
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "MutatingWebhookConfiguration"
      json_pointers = ["/webhooks/0/clientConfig/caBundle"]
    }

    ignore_difference {
      group = "rbac.authorization.k8s.io"
      kind  = "ClusterRole"
      jq_path_expressions = [
        ".rules"
      ]
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }

  depends_on = [
    resource.argocd_application.central-dashboard,
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.oauth2-proxy,
    resource.argocd_application.dex,
    resource.argocd_application.kubeflow-configs,
    resource.argocd_application.central-dashboard,
    resource.argocd_application.admission-webhook,
  ]
}
