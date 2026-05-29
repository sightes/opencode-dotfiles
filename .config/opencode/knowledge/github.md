# GitHub Knowledge Base

GitHub workflows, repository management, collaboration patterns, and CI/CD practices.

## How to Use This File

1. **Repository setup**: Best practices for creating and organizing repos
2. **Pull requests**: Templates, review processes, and merge strategies
3. **Actions**: CI/CD pipeline design and troubleshooting
4. **Project management**: Issues, projects, milestones, and automation
5. **Security**: Secrets management, dependency scanning, access control
6. **Collaboration**: Teams, forks, and open source workflows

---

## Repository Structure & Organization

### Monorepo vs Polyrepo

**Use Monorepo when:**
- Tight coupling between components
- Shared libraries used by multiple apps
- Need atomic changes across services
- Team is small-medium (<100 devs)

**Use Polyrepo when:**
- Teams are fully autonomous
- Services deploy independently
- Different release cycles
- Need clear ownership boundaries

### Directory Structure Best Practices

```
project-root/
├── .github/
│   ├── workflows/           # GitHub Actions
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   └── CODEOWNERS           # Review assignments
├── docs/
│   ├── architecture/        # ADRs, diagrams
│   ├── development/         # Setup guides
│   └── deployment/          # Runbooks
├── src/                     # Application code
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── scripts/                 # Automation scripts
├── config/                  # Configuration files
└── README.md
```

### README.md Essentials

1. **Project title and description** (1-2 sentences)
2. **Badges**: Build status, coverage, version, license
3. **Installation** step-by-step
4. **Quick start** (get running in <5 min)
5. **Usage examples** (copy-paste ready)
6. **Contributing** guidelines link
7. **License**
8. **Contact/Support**

---

## Pull Request Workflow

### Branch Naming Conventions

```
feature/user-authentication
bugfix/login-error-message
hotfix/critical-payment-bug
dependency/update-react-18
refactor/simplify-checkout-flow
docs/api-endpoint-examples
```

### PR Templates

Create `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No console.logs or debug code
```

### Review Best Practices

**For Authors:**
- Keep PRs small (<400 lines when possible)
- One logical change per PR
- Add context in description (screenshots for UI)
- Tag relevant CODEOWNERS
- Respond to feedback within 24 hours

**For Reviewers:**
- Review within 24 hours of request
- Use conventional comments format:
  - `suggestion:` Specific code changes
  - `question:` Unclear logic
  - `nit:` Minor style issues
  - `thought:` Discussion points
  - `issue:` Must fix before merge
  - `praise:` Good work acknowledgment
- Approve only when truly satisfied
- Distinguish between blocking and non-blocking comments

### Merge Strategies

| Strategy | Use When | Pros | Cons |
|----------|----------|------|------|
| **Squash & Merge** | Feature branches | Clean history, easy to revert | Lose granular commit history |
| **Rebase & Merge** | Long-running branches | Linear history, preserves commits | Rewrites history |
| **Merge Commit** | Hotfixes, release branches | Preserves exact history | Messy history graph |

**Recommendation:** Default to **Squash & Merge** for features, **Merge Commit** for releases.

---

## GitHub Actions (CI/CD)

### Workflow Structure

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - run: npm run build
```

### Essential Workflows

**1. CI Pipeline (Every PR):**
- Lint (ESLint, Prettier)
- Unit tests
- Integration tests
- Build verification
- Dependency audit (`npm audit`)
- Coverage report

**2. Deploy Staging (Merge to develop):**
- Build
- Run migrations
- Deploy to staging
- Smoke tests
- Notify team

**3. Deploy Production (Merge to main):**
- Build
- Run migrations
- Deploy to production (with approval)
- Health checks
- Rollback plan ready
- Notify stakeholders

**4. Nightly/Scheduled:**
- Security audit
- Dependency updates (Dependabot PRs)
- Full integration test suite
- Performance benchmarks
- Cleanup (old artifacts, branches)

### Action Best Practices

1. **Pin to major versions**: `actions/checkout@v4` not `@main`
2. **Use caching**: `actions/cache` for dependencies
3. **Matrix builds**: Test multiple Node versions/OS
4. **Secrets**: Use GitHub Secrets, never hardcode
5. **Artifacts**: Upload build artifacts for downstream jobs
6. **Timeouts**: Set `timeout-minutes` to prevent hung jobs
7. **Fail fast**: `fail-fast: false` for matrices (see all failures)

### Common Action Patterns

**Caching Node Modules:**
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
# This automatically caches ~/.npm or node_modules
```

**Conditional Jobs:**
```yaml
if: github.event_name == 'pull_request'
if: contains(github.event.head_commit.message, '[skip ci]')
if: github.ref == 'refs/heads/main'
```

**Reusable Workflows:**
Create `.github/workflows/reusable-test.yml` and call from other workflows:
```yaml
jobs:
  call-test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20'
```

---

## Project Management

### Issue Templates

Create `.github/ISSUE_TEMPLATE/bug_report.md`:
```markdown
---
name: Bug Report
about: Create a report to help us improve
---

**Describe the bug**
A clear description

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen

**Environment:**
- OS: [e.g. macOS 14]
- Browser: [e.g. Chrome 120]
- Version: [e.g. 2.1.0]
```

### Labels System

```
Priority: p0-critical, p1-high, p2-medium, p3-low
Type: bug, feature, enhancement, documentation, refactor
Status: in-progress, blocked, ready-for-review, triage
Area: frontend, backend, database, devops, security, api
Effort: xs, s, m, l, xl
```

### Automation Rules

**Auto-assign PRs:**
Create `.github/CODEOWNERS`:
```
# Global
* @team-leads

# Frontend
/src/ui/ @frontend-team
/src/styles/ @frontend-team

# Backend
/src/api/ @backend-team
/src/models/ @backend-team

# DevOps
/.github/ @devops-team
/docker/ @devops-team
```

**Auto-close stale issues:**
```yaml
name: Stale Issues
on:
  schedule:
    - cron: '0 0 * * *'  # Daily
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          stale-issue-message: 'This issue is stale...'
          days-before-stale: 60
          days-before-close: 7
```

### Project Boards

**Kanban Columns:**
- 📋 Backlog
- 🔄 To Do
- 🏗️ In Progress
- 👀 In Review
- ✅ Done
- 🚫 Blocked

**Automations:**
- PR opened → Move linked issue to "In Review"
- PR merged → Move issue to "Done"
- Issue labeled `bug` → Add to Sprint board

---

## Security Best Practices

### Secrets Management

**DO:**
- Store secrets in GitHub Secrets (Settings > Secrets and variables)
- Use environment-specific secrets (Production, Staging)
- Rotate secrets quarterly
- Use fine-grained PATs (Personal Access Tokens)

**DON'T:**
- ❌ Commit secrets to code
- ❌ Log secrets in CI output
- ❌ Share secrets in Slack/email
- ❌ Use one token for everything

**Scan for secrets:**
```yaml
- name: Secret Detection
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
    head: HEAD
```

### Dependency Security

**Enable Dependabot:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

**Security Advisories:**
- Monitor GitHub Security tab
- Review Dependabot PRs within 48 hours
- Patch critical vulnerabilities within 7 days

### Access Control

**Branch Protection Rules (main branch):**
- Require pull request reviews before merging (1-2 reviewers)
- Require status checks to pass (CI must be green)
- Require branches to be up to date before merging
- Restrict pushes that create files larger than 100MB
- Require linear history (if using rebase workflow)
- Include administrators (enforce for everyone)

**Team Permissions:**
- Admin: Team leads, DevOps
- Write: Developers
- Triage: QA, Product Managers
- Read: Stakeholders, Contractors

---

## Open Source Workflows

### Contributing Guidelines

Create `CONTRIBUTING.md`:
1. Code of Conduct reference
2. Development environment setup
3. Branch naming conventions
4. Commit message format (Conventional Commits)
5. Testing requirements
6. Documentation updates
7. PR process

### Conventional Commits

```
feat: add user authentication
fix: resolve login redirect bug
docs: update API endpoint examples
style: format with prettier
refactor: simplify checkout logic
test: add integration tests for payment
chore: update dependencies
```

**Benefits:**
- Automatic changelog generation
- Semantic versioning (feat=minor, fix=patch, BREAKING=major)
- Clear git history

### Release Workflow

**Semantic Versioning:**
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

**GitHub Releases:**
1. Create release branch: `release/v2.1.0`
2. Update CHANGELOG.md
3. Bump version in package.json
4. Create PR to main
5. After merge, create GitHub Release with tag
6. Auto-generate release notes from PRs
7. Attach build artifacts

**Automated with GitHub Actions:**
```yaml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
```

---

## Troubleshooting Common Issues

**Action fails with "Resource not accessible by integration":**
- Check token permissions (Settings > Actions > General > Workflow permissions)
- May need `permissions: contents: write` in workflow

**Large files in repo:**
- Use Git LFS for files >100MB
- Add to `.gitignore`: `*.log`, `node_modules/`, `.env`, build artifacts

**Slow CI:**
- Use caching (dependencies, build outputs)
- Parallelize jobs
- Use `ubuntu-latest` (faster than Windows/macOS)
- Remove unnecessary steps

**Merge conflicts:**
- Pull latest main before creating feature branch
- Rebase frequently: `git fetch origin && git rebase origin/main`
- Resolve conflicts locally, not in GitHub UI for complex cases

---

## Quick Reference: GitHub CLI (gh)

```bash
# Create PR
gh pr create --title "feat: add auth" --body "Implements OAuth2 login"

# View PR status
gh pr status

# Checkout PR locally
gh pr checkout 123

# Create issue
gh issue create --title "Bug: login fails" --body "Steps: ..."

# View repo
gh repo view --web

# Clone
git clone <repo>
cd <repo>

# Working on feature
git checkout -b feature/new-feature
git add .
git commit -m "feat: implement new feature"
git push origin feature/new-feature
gh pr create

# After review
git add .
git commit --amend --no-edit
git push --force-with-lease

# Merge (after approval)
gh pr merge --squash
```