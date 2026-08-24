# Cursor / ChatGPT Development Workflow

This is the approved development workflow for the Home Cleaning Service Marketplace.

## Workflow

```text
1. ChatGPT prepares one narrowly scoped Cursor task.
2. User gives that exact prompt to Cursor.
3. Cursor performs only the authorized task.
4. Cursor creates the numbered task report.
5. Cursor leaves changes uncommitted.
6. User sends Cursor's complete output/report to ChatGPT.
7. ChatGPT reviews the result.
8. If approved, the user creates a Git commit checkpoint.
9. The next Cursor task begins only from a clean working tree.
```

Exception: if ChatGPT review finds a problem in an uncommitted task before checkpointing, a narrowly scoped review-correction task may operate on that same working tree. This is an exception, not the normal workflow.

## Why this workflow is used

* It limits scope so each task has a clear boundary.
* It makes failures easier to isolate.
* It preserves development history through numbered task reports and Git checkpoints.
* It allows each task to be reviewed before continuation.
* It prevents accidental compounding of incorrect changes.

## Commit policy

Cursor itself must not automatically commit unless a future task explicitly authorizes it.

## Task reports

Task reports remain historical records. They generally should not be rewritten later merely because the project has evolved. If a later task supersedes an earlier decision, the later task should document that change rather than erasing the old history.
