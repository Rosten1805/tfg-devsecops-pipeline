# TFG DevSecOps Pipeline

Pipeline de CI/CD seguro, reutilizable vía `workflow_call` de GitHub Actions,
desarrollado como parte del Trabajo Final de Grado *"Diseño e implementación
de un pipeline CI/CD seguro aplicando prácticas DevSecOps"*.

Este repositorio **es el objeto de estudio del TFG** — el pipeline en sí, con
sus propios requisitos y arquitectura — separado de la aplicación de ejemplo
sobre la que se demuestra
([`Disney-Plus-Clone`](https://github.com/Rosten1805/Disney-Plus-Clone)),
que simplemente lo invoca.

## Cómo se usa

Cualquier repo que quiera aplicar este pipeline añade un workflow mínimo que
lo invoca:

```yaml
name: Security Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  call-pipeline:
    uses: Rosten1805/tfg-devsecops-pipeline/.github/workflows/security-pipeline.yml@main
    secrets: inherit
```

## Etapas

| Etapa | Herramienta | Estado |
|---|---|---|
| SAST | Semgrep + Checkov | Implementado |
| SCA | npm audit | Implementado |
| Escaneo de imagen | Trivy | Pendiente |
| DAST | OWASP ZAP (baseline) | Pendiente |
| IaC / despliegue | Terraform (AWS) | Pendiente |
| Monitorización | CloudWatch Alarms + SNS | Pendiente |

Ver el diseño completo y las decisiones tomadas en
`documentos de entrega/diseno-pipeline-devsecops.md` del repo del TFG.
