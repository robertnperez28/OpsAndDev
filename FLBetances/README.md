# Prueba Técnica DevOps Senior — FLBetances

**Autor:** Robert Pérez

Solución end-to-end para una aplicación ASP.NET Core 8 + SQL Server: contenedor, análisis estático con SonarQube, pipeline CI/CD con dos escenarios (éxito y fallo), publicación de imagen en Docker Hub y despliegue en Kubernetes con manifiestos Kustomize.

---

## Stack

| Capa | Tecnología |
|---|---|
| Aplicación | ASP.NET Core 8 |
| Base de datos | Azure SQL Edge (compatible MS-SQL) |
| Repositorio | GitHub — `robertnperez28/OpsAndDev` |
| CI/CD | Azure DevOps Pipelines (agente self-hosted Windows) |
| Calidad de código | SonarQube Community |
| Registro de imágenes | Docker Hub — `robertnperez/aspnetapp-flbetances` |
| Orquestación | Kubernetes (Minikube) |
| Templating | Kustomize |
| Ingress | NGINX Ingress Controller |

---

## Estructura del repositorio

```
FLBetances/
├── azure-pipelines.yml             # Pipeline escenario éxito
├── azure-pipelines-failed.yml      # Pipeline escenario fallo
├── sonar-project.properties        # Configuración del scanner
├── .editorconfig
├── .gitignore
├── README.md
├── src/                            # Aplicación de producción
│   ├── compose.yaml                # Stack para desarrollo local
│   └── app/aspnetapp/
│       ├── Dockerfile              # Multi-stage, usuario no-root
│       └── ...
├── src-bad/                        # Código con issues (escenario fallo)
│   └── aspnetapp/BadCode.cs
├── environment/                    # Manifiestos Kubernetes
│   ├── base/                       # Recursos comunes
│   └── overlays/dev/               # Overlay del entorno dev
├── scripts/
│   ├── hello-world.ps1             # Job paralelo (10x)
│   └── create-files.ps1            # Genera 10 archivos con fecha
└── docs/
    ├── screenshots/                # Capturas de evidencia
    └── logs/                       # Logs de pipelines descargados
```

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub (push)                          │
└──────────────────────────────┬──────────────────────────────┘
                               │ webhook
┌──────────────────────────────▼──────────────────────────────┐
│         Azure DevOps Pipeline (agente self-hosted)          │
│                                                              │
│  Stage 1: SonarQubeAnalysis                                  │
│   ├─ dotnet sonarscanner begin                               │
│   ├─ dotnet build (interceptado por el scanner)              │
│   └─ dotnet sonarscanner end (espera Quality Gate)           │
│                                                              │
│  Stage 2: DockerBuildPush  (solo si el gate pasó)            │
│   ├─ docker build (multi-stage, no-root)                     │
│   └─ docker push → Docker Hub                                │
│                                                              │
│  Stage 3: ParallelJobs                                       │
│   ├─ Job A: 10 jobs en paralelo "Hola Mundo"                 │
│   └─ Job B: genera 10 archivos con fecha y los imprime       │
│                                                              │
│  Stage 4: DeployK8s                                          │
│   ├─ Actualiza imageTag en kustomization.yaml                │
│   ├─ kubectl apply -k environment/overlays/dev               │
│   └─ Smoke test                                              │
└─────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                       Cluster Minikube                       │
│  Namespace: aspnetapp-dev                                    │
│   ├─ StatefulSet: dev-mssql (PVC 2Gi)                        │
│   ├─ Deployment: dev-aspnetapp-web                           │
│   ├─ Service:    dev-aspnetapp-web (ClusterIP :80→8080)      │
│   └─ Ingress:    dev-aspnetapp-ingress → aspnetapp.local     │
└─────────────────────────────────────────────────────────────┘
```

---

## Los dos escenarios del pipeline

### Escenario 1 — Éxito (`azure-pipelines.yml`)

Se analiza el código de `src/app/`. El Quality Gate de SonarQube pasa, y a partir de ahí el pipeline:

1. Construye y publica la imagen en Docker Hub.
2. Ejecuta los jobs paralelos (10 "Hola Mundo" + generación de 10 archivos con fecha).
3. Aplica los manifiestos a Minikube y corre el smoke test.

### Escenario 2 — Fallo (`azure-pipelines-failed.yml`)

Se analiza la carpeta `src-bad/` que contiene issues a propósito (credenciales hardcoded, SQL injection, código duplicado, etc.). El Quality Gate falla y los stages siguientes quedan en estado *skipped*, demostrando que el gate bloquea el resto del pipeline.

---

## Cómo se cumple cada requisito

| # | Requisito | Dónde está |
|---|---|---|
| 1 | App contenerizada (.NET + MSSQL) | `src/app/aspnetapp/Dockerfile`, `src/compose.yaml` |
| 2 | Código en GitHub público | https://github.com/robertnperez28/OpsAndDev |
| 3 | Pipeline en Azure DevOps | `azure-pipelines.yml` + `azure-pipelines-failed.yml` |
| 4 | Integración con SonarQube | Stage 1 del pipeline |
| 5 | Quality Gate enforcing | `sonar.qualitygate.wait=true` |
| 6 | Compila después de pasar Sonar | Stage 2 con `dependsOn: SonarQubeAnalysis` y `condition: succeeded()` |
| 7.a | Imprimir Hola Mundo 10 veces en paralelo | Stage 3 → job `HelloWorldParallel` con `strategy: parallel: 10` |
| 7.b | Script que crea 10 archivos con fecha y los imprime | Stage 3 → job `GenerateFiles` ejecutando `scripts/create-files.ps1` |
| 8 | Dos escenarios (éxito + fallo) | Dos pipelines separados |
| 9 | Imagen publicada en registro público | Docker Hub: `robertnperez/aspnetapp-flbetances` |
| 10 | Versionado de imagen | Tag `vMAJOR.MINOR.<BuildId>` + `latest` |
| 11 | Deploy a Kubernetes | Stage 4 + `environment/overlays/dev/` |
| 12 | App accesible vía Ingress | `environment/base/ingress.yaml` → `http://aspnetapp.local` |

---

## URLs de referencia

| Recurso | URL |
|---|---|
| Repo GitHub | https://github.com/robertnperez28/OpsAndDev |
| Carpeta del proyecto | https://github.com/robertnperez28/OpsAndDev/tree/main/FLBetances |
| Pipeline éxito (YAML) | https://github.com/robertnperez28/OpsAndDev/blob/main/FLBetances/azure-pipelines.yml |
| Pipeline fallo (YAML) | https://github.com/robertnperez28/OpsAndDev/blob/main/FLBetances/azure-pipelines-failed.yml |
| Imagen en Docker Hub | https://hub.docker.com/r/robertnperez/aspnetapp-flbetances |
| Tags de la imagen | https://hub.docker.com/r/robertnperez/aspnetapp-flbetances/tags |
| SonarQube proyecto OK (local) | http://localhost:9000/dashboard?id=Prueba-Dummy-FLBetances |
| SonarQube proyecto FAILED (local) | http://localhost:9000/dashboard?id=Prueba-Dummy-FLBetances-FAILED |
| Organización Azure DevOps | https://dev.azure.com/OpsAndDev |
| Proyecto Azure DevOps | https://dev.azure.com/OpsAndDev/FLBetancesDevOps |
| Endpoint local de la app | http://aspnetapp.local |

---

## Evidencias

- **Capturas:** `docs/screenshots/`
- **Logs descargados de pipelines:** `docs/logs/`

---

## Desarrollo local

```bash
cd FLBetances/src
docker compose up -d --build
# http://localhost:8080
docker compose down
```

---

## Despliegue manual a Minikube

```powershell
# 1. Build y push de la imagen
cd FLBetances/src/app/aspnetapp
docker build -t robertnperez/aspnetapp-flbetances:latest .
docker push robertnperez/aspnetapp-flbetances:latest

# 2. Aplicar manifiestos
kubectl apply -k FLBetances/environment/overlays/dev

# 3. Esperar el rollout
kubectl rollout status deployment/dev-aspnetapp-web -n aspnetapp-dev

# 4. Exponer el ingress (terminal aparte, se queda corriendo)
minikube tunnel

# 5. Agregar entrada en hosts (como Administrador, una sola vez)
Add-Content "C:\Windows\System32\drivers\etc\hosts" "127.0.0.1 aspnetapp.local"

# 6. Abrir
start http://aspnetapp.local
```

---

## SonarQube

- URL local: `http://localhost:9000`
- Proyectos:
  - `Prueba-Dummy-FLBetances` → código sano, Quality Gate pasa.
  - `Prueba-Dummy-FLBetances-FAILED` → código con issues, Quality Gate falla.

---

## Limpieza

```powershell
kubectl delete -k FLBetances/environment/overlays/dev
minikube stop
```
