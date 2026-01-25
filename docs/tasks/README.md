# Task Organization

This directory contains task documentation organized by status.

## Directory Structure

### `active/`
Currently in-progress tasks. Move tasks here when you start working on them.

### `future/`
Planned future tasks, enhancements, and known issues. This includes:
- Feature ideas and planned improvements
- Known bugs and issues
- Technical improvements
- Research and exploration tasks

### `completed/`
Completed task documentation. Move tasks here when they're finished to preserve the history of what was done and how.

## Task File Naming

Task files should use descriptive, UPPERCASE names with underscores:
- `ACTIVE_WORKOUT_SET_REORDER_IMPROVEMENTS.md`
- `KNOWN_ISSUES.md`
- `TEMPLATE_SYSTEM_RETHINK.md`

## Task File Structure

Each task file should include:
- **Title** - Clear description of the task
- **Status** - Current status (Not Started, In Progress, Complete)
- **Description** - What needs to be done
- **Implementation Notes** - Technical details and approach
- **Related Files** - Files that will be modified or created
- **Dependencies** - Other tasks or features this depends on

## Moving Tasks

When a task status changes:
1. **Starting work**: Move from `future/` to `active/`
2. **Completing work**: Move from `active/` to `completed/`
3. **Cancelling**: Move to `completed/` with a note about cancellation

## Related Documentation

- See [FEATURES.md](../development/FEATURES.md) for complete feature documentation
- See [KNOWN_ISSUES.md](./future/KNOWN_ISSUES.md) for known bugs and issues
- See [TODO.md](./future/TODO.md) for planned features and enhancements
