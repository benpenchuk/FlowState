# Git Workflow Reference

## Repository
**URL:** https://github.com/benpenchuk/FlowState

## Daily Workflow

### Start Working
```bash
cd ~/Documents/Learning/FlowState/FlowState
git status                    # Check current state
git pull                      # Get latest changes
```

### Save Your Work
```bash
git add .                     # Stage all changes
git commit -m "description"   # Commit with message
git push                      # Push to remote
```

## Branching Workflow

### Create & Switch to New Branch
```bash
git checkout -b branch-name   # Create and switch to new branch
git push --set-upstream origin branch-name  # Push and set upstream
```

### Switch Between Branches
```bash
git checkout main             # Switch to main branch
git checkout branch-name      # Switch to feature branch
```

### Stash Work in Progress
```bash
git stash                     # Save uncommitted changes
git stash pop                 # Restore stashed changes
git stash list                # See saved stashes
```

## Essential Commands

| Action | Command |
|--------|---------|
| Check status | `git status` |
| See changes | `git diff` |
| Stage all files | `git add .` |
| Commit changes | `git commit -m "message"` |
| Push commits | `git push` |
| Pull latest | `git pull` |
| Create branch | `git checkout -b name` |
| Switch branch | `git checkout name` |
| Stash changes | `git stash` |
| Restore stash | `git stash pop` |

## Commit Message Examples

- `"rest timer"` - Feature implementation
- `"add comments"` - Documentation
- `"fix bug"` - Bug fixes
- `"update UI"` - UI improvements

## Common Scenarios

### Working on a Feature
```bash
# Start new feature
git checkout -b feature-name
git push --set-upstream origin feature-name

# Work and commit
git add .
git commit -m "feature work"
git push

# Switch back to main when done
git checkout main
git pull
```

### Switching Branches with Uncommitted Changes
```bash
# Save current work
git stash

# Switch branches
git checkout other-branch

# Restore work (if needed)
git stash pop
```

### Pushing New Branch First Time
```bash
git checkout -b new-branch
# Make changes...
git add .
git commit -m "changes"
git push --set-upstream origin new-branch
```

## Tips

- Always `git pull` before starting work
- Use descriptive branch names (e.g., `scrolling-feature`, `bug-fix-timer`)
- Commit often with clear messages
- Use `git status` frequently to check your state