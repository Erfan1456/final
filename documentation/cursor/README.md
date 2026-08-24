# Cursor Task Documentation

This directory stores the historical record of Cursor development tasks for the Home Cleaning Service Marketplace.

Each task is documented as a numbered report so later work can be reviewed against the original prompt, the files that changed, and the verification that was performed.

## Development cycle

Development follows this cycle:

```text
ChatGPT prepares one scoped Cursor task
        ↓
User gives the task to Cursor
        ↓
Cursor executes the task
        ↓
Cursor creates/updates the corresponding task report
        ↓
User sends Cursor's complete result back to ChatGPT
        ↓
ChatGPT reviews the result
        ↓
Only then is the next Cursor task prepared
```

## Task numbering

Tasks are sequentially numbered:

```text
001
002
003
004
...
```

## Filename convention

Use the filename convention:

```text
NNN_short_task_name.md
```

Example:

```text
001_repository_documentation_bootstrap.md
002_repository_foundation.md
003_flutter_architecture_bootstrap.md
```

These examples are naming examples only and must not imply that later tasks have already been approved or completed.

## Report template

New task reports should follow:

```text
documentation/cursor/task-report-template.md
```

## Historical records

Task reports are historical records and generally should NOT be rewritten later merely because the project has evolved.

If a later task supersedes an earlier decision, the later task should document that change rather than erasing the old history.
