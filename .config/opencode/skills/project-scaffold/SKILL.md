---
name: project-scaffold
description: Scaffolding de proyectos con deploy via GitHub Actions → Jenkins → Docker Compose. Use when setting up new projects, CI/CD pipelines, infrastructure scaffolding, or Docker deployment.
---

# project-scaffold

Scaffolding de proyectos con deploy via GitHub Actions → Jenkins → Docker Compose.

## Stack

| Capa | Herramienta |
|------|-------------|
| Trigger | GitHub Actions (push a `prod`) |
| CI/CD | Jenkins con "Trigger builds remotely" + token |
| Deploy | Docker Compose (build local en servidor vía SSH) |
| Registry | Opcional (GHCR, Docker Hub) |

## Arquitectura general

```
proyecto/
├── .github/workflows/trigger-jenkins.yml
├── Jenkinsfile
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── .gitignore
```

---

## Templates por stack

### 1. Rust + TypeScript (fullstack)

Frontend TypeScript (Next.js/Vite), backend Rust (Actix/Axum).

```
proyecto/
├── frontend/
│   ├── src/
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.ts       # output: "standalone"
│   └── Dockerfile.frontend
├── backend/
│   ├── src/
│   ├── Cargo.toml
│   └── Dockerfile.backend
├── docker-compose.yml       # multi-service
├── Jenkinsfile
├── .github/workflows/trigger-jenkins.yml
├── .env.example
└── .gitignore
```

**docker-compose.yml:**
```yaml
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.frontend
    container_name: mi-app-frontend
    ports:
      - "${FE_PORT:-3000}:8080"
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.backend
    container_name: mi-app-backend
    ports:
      - "${BE_PORT:-8080}:8080"
```

**Jenkinsfile:**
```groovy
pipeline {
    agent any
    stages {
        stage('Create env') {
            steps { sh '''
cat > .env <<EOF
FE_PORT=3000
BE_PORT=8080
EOF''' }
        }
        stage('Deploy') {
            steps { sh '''
docker compose -p mi-app down
docker compose -p mi-app up -d --build --remove-orphans''' }
        }
    }
}
```

---

### 2. Python + TypeScript (fullstack)

Frontend TypeScript (Next.js/Vite), backend Python (FastAPI/Django/Flask).

```
proyecto/
├── frontend/
│   ├── src/
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.ts
│   └── Dockerfile.frontend
├── backend/
│   ├── app/
│   ├── requirements.txt o pyproject.toml
│   ├── Dockerfile.backend
│   └── entrypoint.sh
├── docker-compose.yml
├── Jenkinsfile
├── .github/workflows/trigger-jenkins.yml
├── .env.example
└── .gitignore
```

**Dockerfile.backend (FastAPI):**
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV PORT=8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

---

### 3. Python solo (API o script)

Backend Python puro (FastAPI, Django, o script).

```
proyecto/
├── app/
│   ├── main.py
│   ├── routers/
│   └── models/
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── .github/workflows/trigger-jenkins.yml
├── .env.example
├── .gitignore
└── entrypoint.sh
```

---

## Arquitectura por tipo de proyecto

### Services (sitios web, APIs)

Proyecto standalone con uno o más servicios.

**Archivos clave:** `Dockerfile`, `docker-compose.yml`, `Jenkinsfile`, `trigger-jenkins.yml`

```yaml
# docker-compose.yml
services:
  app:
    build: .
    container_name: mi-service
    ports:
      - "${PORT}:8080"
    restart: unless-stopped
```

---

### Runners (functions con crons)

Funciones ejecutadas por cron o bajo demanda. Opcional: crons configurables vía env vars.

```
proyecto/
├── src/
│   ├── main.py / main.rs         # entrypoint
│   ├── handlers/                 # funciones individuales
│   └── scheduler.py             # lógica de cron si aplica
├── Dockerfile
├── cron.yaml                     # definición de crons
├── docker-compose.yml
├── Jenkinsfile
├── .github/workflows/trigger-jenkins.yml
├── .env.example
└── entrypoint.sh
```

**docker-compose.yml con cron:**
```yaml
services:
  runner:
    build: .
    container_name: mi-runner
    restart: unless-stopped
    env_file: .env
    command: ["python", "src/main.py"]

  scheduler:
    build: .
    container_name: mi-scheduler
    restart: unless-stopped
    env_file: .env
    command: ["python", "src/scheduler.py"]
```

**cron.yaml:**
```yaml
jobs:
  - name: daily_cleanup
    schedule: "0 6 * * *"
    handler: handlers.cleanup
  - name: hourly_sync
    schedule: "0 * * * *"
    handler: handlers.sync
```

---

### Task systems (colas de API calls)

Sistema de colas con workers. Usa Redis/RabbitMQ como broker.

```
proyecto/
├── src/
│   ├── worker.py           # consume tareas
│   ├── producer.py         # encola tareas vía API
│   └── tasks/
│       ├── api_call.py
│       └── notifications.py
├── Dockerfile
├── docker-compose.yml      # incluye redis y worker
├── Jenkinsfile
├── .github/workflows/trigger-jenkins.yml
├── .env.example
└── .gitignore
```

**docker-compose.yml:**
```yaml
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped

  api:
    build: .
    container_name: mi-task-api
    ports:
      - "${API_PORT}:8080"
    depends_on:
      - redis
    command: ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]

  worker:
    build: .
    container_name: mi-task-worker
    depends_on:
      - redis
    command: ["python", "src/worker.py"]
    restart: unless-stopped
```

---

### Apps completas

Combinación de frontend + backend + DB + workers.

```
proyecto/
├── frontend/
├── backend/
├── worker/
├── docker-compose.yml
├── Dockerfile.frontend
├── Dockerfile.backend
├── Dockerfile.worker
├── Jenkinsfile
├── .github/workflows/trigger-jenkins.yml
├── .env.example
├── .gitignore
└── nginx/
    └── default.conf
```

---

### Bases de datos desplegables

Base de datos con estructura de carpetas para esquemas, migraciones, seeds.

```
proyecto/
├── db/
│   ├── migrations/
│   ├── seeds/
│   ├── schemas/
│   └── init.sql
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── .env.example
└── .gitignore
```

**docker-compose.yml:**
```yaml
services:
  db:
    build:
      context: ./db
    container_name: mi-db
    ports:
      - "${DB_PORT:-5432}:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    restart: unless-stopped

volumes:
  pgdata:
```

**.env.example:**
```env
DB_PORT=5432
DB_NAME=myapp
DB_USER=admin
DB_PASSWORD=changeme
```

---

## Archivos comunes a TODOS los proyectos

### `.github/workflows/trigger-jenkins.yml`

```yaml
name: Trigger Jenkins

on:
  push:
    branches: [prod]
  workflow_dispatch:

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Jenkins pipeline
        run: |
          curl -k -X POST "${{ secrets.JENKINS_URL }}/job/MI_PROYECTO/build?token=TOKEN_AQUI"
```

> Cambiar `MI_PROYECTO` por el nombre del job en Jenkins y `TOKEN_AQUI` por el build trigger token.

### `Jenkinsfile`

```groovy
pipeline {
    agent any
    stages {
        stage('Create env') {
            steps { sh '''
cat > .env <<EOF
PORT=6060
EOF''' }
        }
        stage('Deploy') {
            steps { sh '''
docker compose -p mi-proyecto down
docker compose -p mi-proyecto up -d --build --remove-orphans''' }
        }
    }
}
```

### `.gitignore`

```gitignore
node_modules/
.env
.env.*
!.env.example
```

### GitHub Secrets necesarios

| Secret | Ejemplo |
|--------|---------|
| `JENKINS_URL` | `https://jk.sght.cl` |

---

## Flujo completo (nuevo proyecto)

1. Crear repo en GitHub
2. Elegir template según stack (Rust+TS / Python+TS / Python)
3. Elegir arquitectura según tipo (service / runner / task / app / db)
4. Copiar archivos base del template correspondiente
5. Cambiar nombres (`mi-proyecto`, `MI_PROYECTO`, `TOKEN_AQUI`)
6. Agregar `JENKINS_URL` como GitHub Secret
7. En Jenkins: crear pipeline con "Trigger builds remotely" usando el mismo token
8. Agregar deploy key SSH a GitHub
9. Push a `prod` y probar
