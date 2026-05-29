---
description: Safe and clean git commit with best practices
agent: build
model: opencode/big-pickle
---

Perform a safe git commit following best practices.

Steps:

1. Ensure repository is up to date:
   - Check current branch
   - Pull latest changes from remote
   - Warn about merge conflicts if any

2. Analyze git status:
   - Identify modified, staged, and untracked files
   - Only include relevant modified files
   - Do NOT include unrelated or large files

3. Ignore sensitive and unnecessary files:
   - Exclude files like:
     - .env, .env.*
     - node_modules/
     - dist/, build/
     - *.log
     - coverage/
     - .DS_Store
     - any file containing secrets or credentials
   - Suggest updates to .gitignore if needed

4. Review code quality:
   - Detect debug code (console.log, print, TODOs)
   - Detect commented-out code
   - Warn about potential secrets
   - Ensure no accidental large/binary files are included

5. Validate changes:
   - Ensure changes are logically grouped
   - Suggest splitting into multiple commits if necessary

6. Generate commit message using Conventional Commits:
   Format:
   - type(scope): short description

   Types:
   - feat: new feature
   - fix: bug fix
   - refactor: code improvement
   - test: test changes
   - docs: documentation
   - chore: maintenance

   Include:
   - Clear description
   - Optional body explaining why

7. Stage ONLY the selected relevant files

8. Show:
   - Files to be committed
   - Proposed commit message

9. Ask for confirmation before committing

10. After confirmation:
   - Create commit
   - Suggest next step (push or PR)