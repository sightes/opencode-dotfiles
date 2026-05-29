# Deploy Knowledge Base

Deployment strategies, infrastructure patterns, CI/CD pipelines, and release management.

## How to Use This File

1. **Environment setup**: Local, staging, production configurations
2. **Deployment strategies**: Blue-green, canary, rolling updates
3. **Platform selection**: When to use Vercel, AWS, Docker, etc.
4. **Rollback procedures**: Emergency recovery and data safety
5. **Monitoring**: Health checks, logging, alerting post-deploy
6. **Security**: Secrets management, access control, compliance

---

## Deployment Strategies

### 1. Blue-Green Deployment

**How it works:**
- Two identical production environments (Blue = current, Green = new)
- Route traffic to Blue
- Deploy new version to Green, run smoke tests
- Switch traffic to Green
- Keep Blue running for quick rollback

**Pros:**
- Zero downtime
- Instant rollback
- Easy A/B testing

**Cons:**
- Double infrastructure cost
- Complex database migrations (both versions must be compatible)

**Best for:** Critical financial systems, healthcare, e-commerce checkout

**Implementation:**
```yaml
# With Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.2.0
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 0  # Start at 0, scale up after deployment
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.3.0
```

### 2. Canary Deployment

**How it works:**
- Deploy new version to small subset of users (5%)
- Monitor metrics (errors, latency, business metrics)
- Gradually increase traffic (5% → 25% → 50% → 100%)
- Rollback if issues detected

**Pros:**
- Risk mitigation
- Real user testing
- Performance validation

**Cons:**
- Requires sophisticated routing
- Slower rollout
- Complex monitoring

**Best for:** Large user bases, consumer apps, microservices

**Implementation:**
```nginx
# Nginx weighted load balancing
upstream backend {
    server blue-v1:8080 weight=95;
    server green-v2:8080 weight=5;
}
```

### 3. Rolling Deployment

**How it works:**
- Gradually replace old instances with new ones
- Take one instance down, deploy new version, bring back up
- Repeat until all instances updated

**Pros:**
- No extra infrastructure
- Simple to implement
- Built into most platforms

**Cons:**
- Brief capacity reduction during deploy
- Rollback is slow
- Multiple versions running simultaneously

**Best for:** Standard web applications, Kubernetes defaults

**Implementation:**
```yaml
# Kubernetes rolling update
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%  # Minimum instances available
      maxSurge: 25%        # Maximum extra instances
```

### 4. Feature Flags (Dark Launch)

**How it works:**
- Deploy code to production but hide behind feature flags
- Enable for specific users/groups
- Test in production without exposing to all users

**Pros:**
- Deploy independently of release
- Gradual rollout
- Easy kill switch

**Cons:**
- Code complexity
- Flag management overhead
- Technical debt if flags aren't cleaned up

**Tools:** LaunchDarkly, Unleash, ConfigCat, custom implementation

---

## Environment Strategy

### The 4+ Environments

| Environment | Purpose | Data | Uptime | Access |
|------------|---------|------|--------|--------|
| **Local** | Development | Synthetic/Local | N/A | Developer |
| **Dev** | Integration testing | Synthetic | 90% | Team |
| **QA/Staging** | Pre-production validation | Anonymized prod clone | 95% | Team + QA |
| **Production** | Live users | Real | 99.9%+ | Limited |
| **DR** | Disaster recovery | Prod replica | On-demand | Ops only |

### Configuration Management

**12-Factor App: Config in Environment**

```bash
# ❌ DON'T: Hardcode or commit configs
const dbHost = 'prod-db.example.com'

# ✅ DO: Use environment variables
const dbHost = process.env.DATABASE_HOST
```

**Environment Files:**
```bash
# .env.local (developer, gitignored)
DATABASE_URL=postgresql://localhost/dev_db
API_KEY=dev-key

# .env.staging (shared team config)
DATABASE_URL=postgresql://staging-db/staging
API_KEY=staging-key

# Production: Set via platform (AWS Secrets, Vercel Env, etc.)
# NEVER commit production secrets
```

**Runtime Validation:**
```typescript
import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(20),
  PORT: z.string().transform(Number).default('3000')
})

// Throws if required env vars missing or invalid
export const env = envSchema.parse(process.env)
```

---

## Platform-Specific Guides

### Vercel (Frontend/Full-Stack)

**Best for:** Next.js, React, Vue, Svelte, static sites

```bash
# Deploy from CLI
vercel --prod

# Preview deployment (per-branch)
# Automatic with git integration
```

**Configuration (`vercel.json`):**
```json
{
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/api/$1"
    }
  ],
  "env": {
    "DATABASE_URL": "@database-url"
  },
  "github": {
    "enabled": true,
    "autoAlias": true
  }
}
```

**Features:**
- Preview deployments per PR
- Edge Network CDN
- Serverless Functions
- Analytics
- Image Optimization

### Docker + Kubernetes (Backend/Microservices)

**Multi-stage Dockerfile:**
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine AS production
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

**Kubernetes Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: myregistry/api:v1.2.3
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Service & Ingress:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```

### AWS (Enterprise/Infrastructure)

**Common Services:**

| Service | Use Case |
|---------|----------|
| **EC2/ECS** | Container orchestration |
| **Lambda** | Serverless functions |
| **S3** | Static hosting, assets |
| **RDS** | Managed databases |
| **CloudFront** | CDN |
| **Route 53** | DNS |
| **API Gateway** | API management |
| **CodePipeline** | CI/CD |

**Serverless (Lambda + API Gateway):**
```yaml
# serverless.yml
service: my-api

provider:
  name: aws
  runtime: nodejs20.x
  stage: ${opt:stage, 'dev'}
  region: us-east-1
  environment:
    DATABASE_URL: ${env:DATABASE_URL}

functions:
  api:
    handler: handler.main
    events:
      - http:
          path: /{proxy+}
          method: ANY
          cors: true
```

### Railway / Render / Fly.io (Simple Backend)

**Railway:**
```bash
# Connect GitHub repo
# Auto-deploy on push to main
# Environment variables in dashboard
railway link
railway variables set DATABASE_URL=postgresql://...
railway up
```

**Fly.io:**
```bash
fly launch
fly deploy
# Automatic TLS, global CDN
```

---

## Database Deployment

### Migrations

**NEVER:**
- ❌ Modify existing migrations
- ❌ Delete migration files that ran in production
- ❌ Run migrations manually in production

**ALWAYS:**
- ✅ Create new migrations for changes
- ✅ Test migrations in staging
- ✅ Backup before deploying migrations
- ✅ Use transactions for data migrations
- ✅ Make migrations backward-compatible (when possible)

**Migration Strategy:**
```typescript
// Expand-contract pattern for zero-downtime
// Step 1: Expand - Add new column, write to both
migration.addColumn('users', 'email_v2')
migration.update('users', { email_v2: email })

// Step 2: Update code to read from new, write to both
// Deploy

// Step 3: Contract - Remove old column
migration.removeColumn('users', 'email')
// Deploy
```

### Seeding Data

```typescript
// Separate seed files per environment
// seeds/development.ts - Fake data for dev
// seeds/staging.ts - Anonymized production subset
// seeds/production.ts - Essential data only (roles, settings)
```

---

## Health Checks & Monitoring

### Application Health Endpoints

```typescript
// /health - Liveness (Kubernetes)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'alive' })
})

// /ready - Readiness (can accept traffic)
app.get('/ready', async (req, res) => {
  try {
    await db.query('SELECT 1')
    await cache.ping()
    res.status(200).json({ status: 'ready' })
  } catch {
    res.status(503).json({ status: 'not ready' })
  }
})

// /metrics - Prometheus metrics
app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType)
  res.end(register.metrics())
})
```

### Post-Deploy Verification

```bash
#!/bin/bash
# deploy-verify.sh

URL="https://api.example.com"

# 1. Health check
curl -f "${URL}/health" || exit 1

# 2. Key functionality
curl -f "${URL}/api/users" || exit 1

# 3. Response time
curl -o /dev/null -s -w "%{time_total}" "${URL}/health"

# 4. Error rate (check logs)
# Query monitoring system

echo "✅ Deployment verified"
```

---

## Rollback Strategy

### When to Rollback

- Error rate > threshold (e.g., 1% → 5%)
- Latency > threshold (e.g., p95 > 500ms)
- Critical business metrics drop
- Security vulnerability discovered
- Data corruption detected

### Rollback Procedures

**1. Instant (Blue-Green):**
```bash
# Switch traffic back to Blue
kubectl patch service app -p '{"spec":{"selector":{"version":"blue"}}}'
```

**2. Quick (Docker/Kubernetes):**
```bash
# Revert to previous image
kubectl rollout undo deployment/app
# Or specify revision
kubectl rollout undo deployment/app --to-revision=2
```

**3. Database Rollback:**
```bash
# ⚠️ NEVER rollback migrations automatically
# Always have backward-compatible migrations
# If data loss risk: Restore from backup
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-db \
  --target-db-instance-identifier prod-db-rollback \
  --restore-time "2024-01-15T10:00:00Z"
```

### Rollback Checklist

- [ ] Alert team (Slack/PagerDuty)
- [ ] Identify cause (logs, metrics)
- [ ] Execute rollback
- [ ] Verify rollback success
- [ ] Monitor for 30 minutes
- [ ] Post-mortem within 24 hours
- [ ] Fix issue in new version
- [ ] Deploy fixed version

---

## Security in Deployment

### Secrets Management

**Level 1 - Environment Variables:**
```bash
# .env (gitignored, never commit!)
DATABASE_URL=postgresql://...
API_KEY=sk-live-...
```

**Level 2 - Secret Managers:**
- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault
- GCP Secret Manager

**Level 3 - Runtime Injection:**
```yaml
# Kubernetes
spec:
  containers:
  - name: app
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database-url
```

### Access Control

```yaml
# Restrict deployment permissions
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["create", "update", "patch"]
    resourceNames: ["app-staging"]
  # Production requires approval workflow
```

### Compliance

- SOC 2: Change management logs
- HIPAA: Encryption at rest/transit, audit logs
- PCI DSS: Network segmentation, tokenization
- GDPR: Data residency, right to deletion

---

## CI/CD Pipeline Example (Complete)

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build

  security:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=moderate

  deploy-staging:
    needs: [test, security]
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Staging
        run: |
          docker build -t app:staging .
          docker push app:staging
          kubectl set image deployment/app app=app:staging
      - name: Smoke Tests
        run: |
          sleep 30
          curl -f https://staging.example.com/health

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Production
        run: |
          docker build -t app:v${{ github.run_number }} .
          docker push app:v${{ github.run_number }}
          kubectl set image deployment/app app=app:v${{ github.run_number }}
      - name: Verify Deployment
        run: |
          sleep 30
          curl -f https://api.example.com/health
          curl -f https://api.example.com/ready
```

---

## Deployment Checklist

### Pre-Deploy
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Database migrations prepared and tested
- [ ] Feature flags configured (if using)
- [ ] Rollback plan ready
- [ ] Backup completed (database, critical data)
- [ ] Monitoring dashboards verified
- [ ] On-call engineer notified

### During Deploy
- [ ] Deploy to staging first
- [ ] Run smoke tests in staging
- [ ] Monitor error rates (should be <0.1%)
- [ ] Monitor latency (p95 should not increase >20%)
- [ ] Monitor business metrics (conversions, signups)
- [ ] Check logs for warnings/errors

### Post-Deploy
- [ ] Verify in production
- [ ] Run critical user journeys
- [ ] Monitor for 1 hour (critical) or 24 hours (standard)
- [ ] Announce deployment completion
- [ ] Update runbooks if needed
- [ ] Schedule post-mortem if issues occurred