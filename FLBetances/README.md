# Prueba Técnica DevOps Senior - FLBetances

End-to-end DevOps solution covering CI/CD, static code analysis, containerization, orchestration and Infrastructure-as-Code style manifests for a containerized ASP.NET Core 8 + SQL Server application.

## Author
Robert Perez

## Stack

| Layer | Technology |
|---|---|
| Application | ASP.NET Core 8 (modernized from official Docker sample `aspnet-mssql`) |
| Database | Azure SQL Edge (MS-SQL compatible) |
| Source control | GitHub (`robertnperez28/OpsAndDev`) |
| CI/CD | Azure DevOps Pipelines (Self-Hosted Agent) |
| Code quality | SonarQube Community 26.x |
| Container registry | Docker Hub (`robertnperez/aspnetapp-flbetances`) |
| Orchestration | Kubernetes (Minikube) |
| Templating | Kustomize (overlay-based) |
| Ingress | NGINX Ingress Controller |

## Repository structure

```
FLBetances/
├── azure-pipelines.yml             # Main pipeline (success scenario)
├── azure-pipelines-failed.yml      # Failure scenario (Quality Gate blocks)
├── sonar-project.properties        # SonarQube config (CLI fallback)
├── .editorconfig                   # Coding standards
├── .gitignore
├── README.md
├── src/                            # Production app (ASP.NET Core 8)
│   ├── compose.yaml                # Local dev stack (web + db)
│   └── app/aspnetapp/
│       ├── Dockerfile              # Multi-stage, non-root user
│       ├── aspnetapp.csproj
│       ├── Program.cs
│       ├── Startup.cs
│       └── ...
├── src-bad/                        # Intentionally bad code (failure scenario)
│   └── aspnetapp/
│       ├── BadCode.cs              # SQL injection, hardcoded secrets, etc.
│       └── ...
├── environment/                    # Kubernetes manifests
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── mssql-secret.yaml
│   │   ├── mssql-pvc.yaml
│   │   ├── mssql-statefulset.yaml
│   │   ├── web-deployment.yaml
│   │   └── ingress.yaml
│   └── overlays/
│       └── dev/
│           └── kustomization.yaml
├── scripts/
│   ├── hello-world.sh              # Used by parallel job
│   └── create-files.sh             # Generates 10 files with date
└── docs/
    └── screenshots/                # Evidence captures
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub repo (push)                     │
└──────────────────────────────┬──────────────────────────────┘
                               │ webhook
┌──────────────────────────────▼──────────────────────────────┐
│              Azure DevOps Pipeline (Self-Hosted)            │
│                                                              │
│  Stage 1: SonarQubeAnalysis                                  │
│   ├─ dotnet restore + build                                  │
│   ├─ SonarQubePrepare (scanner for MSBuild)                  │
│   ├─ SonarQubeAnalyze                                        │
│   └─ SonarQubePublish (Quality Gate WAIT)                    │
│                                                              │
│  Stage 2: DockerBuildPush (only if gate PASS)                │
│   ├─ docker build (multi-stage, non-root)                    │
│   └─ docker push → Docker Hub                                │
│                                                              │
│  Stage 3: ParallelJobs                                       │
│   ├─ Job A: 10 parallel "Hola Mundo" jobs                    │
│   └─ Job B: Generate 10 dated files + cat                    │
│                                                              │
│  Stage 4: DeployK8s                                          │
│   ├─ Update image tag in kustomization.yaml                  │
│   ├─ kubectl apply -k environment/overlays/dev               │
│   └─ Smoke test                                              │
└─────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                       Minikube cluster                       │
│  Namespace: aspnetapp-dev                                    │
│   ├─ StatefulSet: dev-mssql (PVC 2Gi)                        │
│   ├─ Deployment: dev-aspnetapp-web (1 replica)               │
│   ├─ Service:    dev-aspnetapp-web (ClusterIP :80→8080)      │
│   └─ Ingress:    dev-aspnetapp-ingress → aspnetapp.local     │
└─────────────────────────────────────────────────────────────┘
```

## Pipeline scenarios

### Success scenario (`azure-pipelines.yml`)
1. Code is analyzed by SonarQube → **Quality Gate passes**
2. Docker image is built & pushed to Docker Hub
3. Parallel jobs run (10x Hello World + 10 files generation)
4. App is deployed to Minikube via Kustomize

### Failure scenario (`azure-pipelines-failed.yml`)
1. Targets `src-bad/` folder containing intentional issues:
   - Hardcoded credentials (security hotspot)
   - SQL injection vulnerability
   - Empty catch blocks
   - Dead code, magic numbers, duplicated blocks
2. SonarQube Quality Gate **fails**
3. The pipeline stops at Stage 1 → Docker/K8s stages never execute

## Local development

```bash
# Run app + db locally
cd FLBetances/src
docker compose up -d --build
# Open http://localhost:8080
docker compose down
```

## Deploy to Minikube manually

```powershell
# 1. Build & push
cd FLBetances/src/app/aspnetapp
docker build -t robertnperez/aspnetapp-flbetances:latest .
docker push robertnperez/aspnetapp-flbetances:latest

# 2. Apply manifests
kubectl apply -k FLBetances/environment/overlays/dev

# 3. Wait for rollout
kubectl rollout status deployment/dev-aspnetapp-web -n aspnetapp-dev

# 4. Expose ingress (in a separate terminal, keep running)
minikube tunnel

# 5. Add hosts entry (run as Administrator)
Add-Content "C:\Windows\System32\drivers\etc\hosts" "127.0.0.1 aspnetapp.local"

# 6. Browse
start http://aspnetapp.local
```

## SonarQube

- URL: `http://localhost:9000`
- Project key: `Prueba-Dummy-FLBetances` (success), `Prueba-Dummy-FLBetances-FAILED` (fail)
- Quality Gate: default Sonar way (waits via `sonar.qualitygate.wait=true`)

## Cleanup

```powershell
# Remove app from cluster
kubectl delete -k FLBetances/environment/overlays/dev

# Stop minikube
minikube stop

# Stop SonarQube
cd C:\OpsAndDev\sonarqube
docker compose down
```

## Bonus features implemented
- ✅ Kustomize as template manager
- ✅ Multi-stage Dockerfile with non-root user
- ✅ Health probes (readiness + liveness)
- ✅ Resource requests/limits
- ✅ StatefulSet + PVC for stateful database
- ✅ Secret for DB credentials (no hardcoded passwords in manifests)
- ✅ Ingress with NGINX controller
- ✅ Self-hosted agent
- ✅ Two pipeline scenarios (success/failure)
- ✅ Coding standards (`.editorconfig`)

## Bonus NOT implemented (and why)
- ❌ Public cloud deployment: limited to local Minikube due to no Azure/AWS credit available. The Kustomize manifests are cloud-portable: switching to AKS/EKS only requires `kubectl config use-context <new-cluster>`.
- ❌ Terraform IaC: documented design but not provisioned (no cloud).
