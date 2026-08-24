# Cursor Task 004 — Flutter Project Identity Baseline

## Metadata

- Task ID: 004
- Task title: Flutter Project Identity Baseline
- Date: 2026-08-24 18:14 +06:00
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Normalize the Flutter/Dart package identity from the generated name `project` to `home_cleaning_marketplace` before architecture and feature development, without renaming the physical `project/` directory, without changing native platform identifiers, and without implementing product functionality.

## Exact Cursor Prompt

````text
# TASK 004 — Flutter Project Identity Baseline

You are working inside the existing Git repository:

```text
D:\freelance\erfankhan_cse489\final
```

Important repository layout:

```text
final/
├── .git/
├── .gitignore
├── README.md
├── documentation/
└── project/                  ← Flutter package root
```

The Flutter package currently came from:

```text
flutter create project
```

and therefore still uses the generic Dart package name:

```text
project
```

TASK 004 will normalize the Flutter package identity before application architecture and feature development begin.

This is intentionally being done while the Flutter application still contains only the generated counter template so that package-renaming churn is minimized.

---

# APPROVED PROJECT CONTEXT

Product:

```text
Home Cleaning Service Marketplace
```

Planned roles:

* Customer
* Cleaner / Service Provider
* Administrator

Mobile technology:

```text
Flutter + Dart
```

Backend technology:

```text
Dart
```

Exact backend framework:

```text
Not yet selected
```

Database:

```text
MongoDB Atlas
```

Intended security boundary:

```text
Flutter application
        ↓
Dart backend API
        ↓
MongoDB Atlas
```

Flutter must never contain the MongoDB Atlas connection URI.

No backend or product functionality is to be implemented in TASK 004.

---

# DECISION FOR THIS TASK

Change the Dart/Flutter package name from:

```text
project
```

to:

```text
home_cleaning_marketplace
```

The human-readable product name is:

```text
Home Cleaning Service Marketplace
```

The Dart package name is intentionally shorter:

```text
home_cleaning_marketplace
```

Do NOT rename the physical directory:

```text
project/
```

The repository layout remains:

```text
final/
└── project/
```

Do NOT change Android application ID / namespace yet.

Do NOT change iOS bundle identifier yet.

Do NOT invent an organization/domain identifier.

Those platform identifiers will be handled separately once a deliberate identifier decision is made.

---

# PURPOSE OF TASK 004

This task must:

1. verify TASK 002 and TASK 003 were checkpointed and the repository starts clean;
2. change the Dart package name from `project` to `home_cleaning_marketplace`;
3. update references/imports affected by that package-name change;
4. improve the Flutter package description;
5. preserve all generated Flutter platform configuration unless directly required by the Dart package rename;
6. run dependency resolution;
7. run formatting where applicable;
8. run Flutter static analysis;
9. run the Flutter test suite;
10. document the identity decision;
11. create TASK 004's Cursor report;
12. leave all TASK 004 changes uncommitted for ChatGPT review.

---

# STRICT SAFETY RULES

For TASK 004:

1. Do NOT implement marketplace features.
2. Do NOT implement login.
3. Do NOT implement signup.
4. Do NOT implement authentication.
5. Do NOT implement MongoDB connectivity.
6. Do NOT create backend code.
7. Do NOT create a backend directory.
8. Do NOT select a backend framework.
9. Do NOT select state management.
10. Do NOT select a routing package.
11. Do NOT add application architecture folders yet.
12. Do NOT add third-party Flutter packages.
13. Do NOT run `flutter pub add`.
14. Do NOT run `flutter pub upgrade`.
15. Do NOT change dependency versions unless Flutter itself requires a lockfile update during normal `flutter pub get`.
16. Do NOT change Android namespace or application ID.
17. Do NOT change Kotlin package paths.
18. Do NOT change iOS bundle identifiers.
19. Do NOT change macOS bundle identifiers.
20. Do NOT change Linux application ID.
21. Do NOT change Windows product identifiers.
22. Do NOT rename `project/`.
23. Do NOT move Flutter files to repository root.
24. Do NOT create `.env`.
25. Do NOT introduce secrets.
26. Do NOT stage.
27. Do NOT commit.
28. Do NOT push.
29. Do NOT modify historical TASK 001–003 reports.
30. Do NOT make unrelated cleanup changes.

Only files genuinely required for the package-identity change, documentation, and resulting lockfile metadata may change.

---

# STEP 1 — VERIFY CLEAN CHECKPOINT

Before modifying anything, run:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -3 --oneline
```

Verify Git root:

```text
D:\freelance\erfankhan_cse489\final
```

Verify branch:

```text
main
```

The working tree MUST be clean before TASK 004 begins.

If:

```bash
git status --short
```

produces any output, STOP.

Do not modify anything.

Report the unexpected working-tree state.

Also verify that:

```text
project/pubspec.lock
```

is now tracked.

Use:

```bash
git ls-files project/pubspec.lock
```

Expected result:

```text
project/pubspec.lock
```

If it is not tracked, STOP and report the issue.

---

# STEP 2 — RECORD CURRENT PACKAGE IDENTITY

Inspect:

```text
project/pubspec.yaml
project/lib/main.dart
project/test/widget_test.dart
```

Search the tracked repository for package references involving:

```text
package:project/
```

and important uses of the standalone package/application name `project`.

Use safe search tools or commands.

Do not blindly replace every occurrence of the word `project`.

Differentiate between:

### Dart package identity

Needs changing now.

### Physical folder name `project/`

Must remain unchanged.

### Android/iOS/macOS/Linux/Windows identifiers

Must remain unchanged in TASK 004.

### Human-readable generated labels

Only change if explicitly authorized later in this prompt.

Record relevant findings.

---

# STEP 3 — UPDATE `pubspec.yaml`

Modify:

```text
project/pubspec.yaml
```

Change:

```yaml
name: project
```

to:

```yaml
name: home_cleaning_marketplace
```

Change the generic description:

```text
A new Flutter project.
```

to a concise project-specific description such as:

```text
Flutter mobile client for the Home Cleaning Service Marketplace.
```

Keep:

* current application version;
* Dart SDK constraint;
* Flutter dependency;
* existing dependencies;
* existing dev dependencies;
* Material configuration.

Do NOT add dependencies.

Do NOT remove dependencies.

Do NOT modify SDK constraints.

---

# STEP 4 — UPDATE DART PACKAGE IMPORTS

Find Dart imports that use:

```dart
package:project/
```

Update only those package-import references to:

```dart
package:home_cleaning_marketplace/
```

The generated test is expected to contain an import similar to:

```dart
import 'package:project/main.dart';
```

which should become:

```dart
import 'package:home_cleaning_marketplace/main.dart';
```

Do not refactor the counter application yet.

Do not replace its UI.

Do not introduce architecture.

The generated counter app remains our temporary baseline until the architecture bootstrap task.

---

# STEP 5 — UPDATE THE FLUTTER PACKAGE README

Inspect:

```text
project/README.md
```

If it remains the default generated Flutter README, replace it with a short package-level README.

It should contain:

```text
# Home Cleaning Service Marketplace — Flutter Client
```

Explain briefly:

* this directory is the Flutter/Dart mobile client;
* its Dart package name is `home_cleaning_marketplace`;
* repository-level documentation lives at `../documentation/`;
* Flutter commands should be executed from this directory;
* the application is currently at the foundation stage.

Include basic commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Do not duplicate the complete root README.

Do not claim application features are implemented.

---

# STEP 6 — DO NOT CHANGE PLATFORM IDENTIFIERS

Explicitly inspect enough configuration to confirm these still retain their current generated identifiers.

At minimum verify:

```text
project/android/app/build.gradle.kts
project/android/app/src/main/AndroidManifest.xml
```

and relevant iOS configuration where identifiable.

TASK 004 must NOT change identifiers such as:

```text
com.example.project
```

This apparent mismatch is deliberate for the moment:

```text
Dart package:
home_cleaning_marketplace

Current platform ID:
com.example.project
```

Document that platform IDs remain deferred because no final organization/domain identity has been selected.

Do not attempt to "fix" the mismatch automatically.

---

# STEP 7 — RUN DEPENDENCY RESOLUTION

From:

```text
project/
```

run:

```bash
flutter pub get
```

This is authorized for TASK 004.

Do NOT run:

```bash
flutter pub upgrade
```

Do NOT add any dependency.

After `flutter pub get`, inspect whether:

```text
pubspec.lock
```

changed.

If it changed, explain exactly why if identifiable.

Do not manually manipulate the lockfile.

---

# STEP 8 — FORMAT RELEVANT DART FILES

Run from the Flutter package:

```bash
dart format lib test
```

The current template should already be formatted, but perform the verification/formatting.

Report any files changed by formatting.

Do not format platform-native directories.

---

# STEP 9 — STATIC ANALYSIS

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found
```

If warnings/errors occur:

* do not suppress them;
* do not broadly refactor;
* determine whether they are caused by TASK 004;
* fix only TASK 004-caused issues when the fix is obvious and within scope;
* otherwise report them.

Re-run analysis after any permitted fix.

---

# STEP 10 — RUN TESTS

Run:

```bash
flutter test
```

The existing template counter widget test should still pass after the package-import rename.

Record:

* number of tests run;
* pass/fail status;
* important command output.

If the test fails because of TASK 004, fix only the package-rename-related problem and rerun.

Do not redesign tests yet.

---

# STEP 11 — VERIFY PACKAGE REFERENCES

Search again for:

```text
package:project/
```

There should be no remaining Dart source/test import using the old package name.

Also verify relevant code now references:

```text
package:home_cleaning_marketplace/
```

Do NOT replace unrelated uses of the ordinary English word `project`.

---

# STEP 12 — DOCUMENT THE PACKAGE IDENTITY DECISION

Create:

```text
documentation/decisions/ADR-002-flutter-package-identity.md
```

Use sections:

```text
# ADR-002 — Flutter Package Identity

## Status
## Context
## Decision
## Scope
## Deferred Decisions
## Consequences
```

Document:

### Status

Accepted.

### Context

The generated Flutter app used the generic package name:

```text
project
```

Leaving this in place while expanding the codebase would cause future imports to use an inappropriate generic namespace and increase rename churn later.

### Decision

Use:

```text
home_cleaning_marketplace
```

as the Dart package name.

Keep the physical Flutter directory:

```text
project/
```

unchanged for now.

### Scope

This ADR affects Dart package identity and package imports only.

### Deferred Decisions

Explicitly defer:

* Android application ID;
* Android namespace;
* iOS bundle identifier;
* macOS bundle identifier;
* Linux application identifier;
* Windows packaging/product identifiers;
* organization/domain ownership;
* store listing identity.

### Consequences

Document that future Dart imports can consistently use:

```dart
package:home_cleaning_marketplace/...
```

while native platform identifiers temporarily remain generated defaults until separately decided.

---

# STEP 13 — UPDATE DOCUMENTATION INDEX

Update:

```text
documentation/decisions/README.md
```

only enough to add a link/reference to:

```text
ADR-002-flutter-package-identity.md
```

Do not rewrite unrelated documentation.

---

# STEP 14 — CREATE TASK 004 REPORT

Create:

```text
documentation/cursor/004_flutter_project_identity_baseline.md
```

Use:

```text
documentation/cursor/task-report-template.md
```

The report must include the COMPLETE EXACT TASK 004 prompt under:

```text
## Exact Cursor Prompt
```

Do not summarize it.

Accurately document:

* clean starting repository state;
* current commit;
* package identity before change;
* files inspected;
* files changed;
* package name change;
* import changes;
* README update;
* `flutter pub get`;
* whether `pubspec.lock` changed;
* formatting result;
* analysis result;
* test result;
* remaining old-package search results;
* unchanged native platform identifiers;
* verification;
* issues/warnings;
* final Git status.

Do not include credentials or secret values.

---

# STEP 15 — SECURITY CHECK

Verify TASK 004 introduced no:

* `.env`;
* MongoDB URI;
* MongoDB credentials;
* API keys;
* tokens;
* passwords;
* private keys.

Do not print secret values.

---

# STEP 16 — REVIEW EXACT FILE CHANGES

Run from the repository root:

```bash
git status --short
git diff -- project/pubspec.yaml
git diff -- project/lib/
git diff -- project/test/
git diff -- project/README.md
git diff -- project/android/
git diff -- project/ios/
git diff -- documentation/
```

Confirm:

* `pubspec.yaml` has only intended package identity/description changes;
* Dart package imports use the new package name;
* counter app behavior itself was not redesigned;
* Android configuration has no changes;
* iOS configuration has no changes;
* documentation changes are within scope.

If `pubspec.lock` changed because of `flutter pub get`, include it in the review and explain.

---

# STEP 17 — FINAL HEALTH VERIFICATION

The final required checks are:

```bash
flutter analyze
flutter test
```

Both must be reported.

Do not claim success if either fails.

---

# STEP 18 — DO NOT COMMIT

Do NOT run:

```bash
git add
git commit
git push
```

Leave TASK 004 changes uncommitted for ChatGPT review.

---

# FINAL RESPONSE FORMAT

Respond with exactly these top-level sections:

# TASK 004 RESULT

## Status

Use:

```text
SUCCESS
PARTIAL
FAILED
```

## Pre-Task Verification

Report:

* Git root
* branch
* starting working-tree status
* latest commit
* whether `project/pubspec.lock` was tracked

## Previous Identity

Report:

```text
Dart package:
Flutter directory:
Android namespace/application ID:
```

## New Dart Package Identity

Report the new Dart package name and description.

## Files Changed

List every changed file.

## Package Import Verification

Report:

* old `package:project/` references remaining;
* new `package:home_cleaning_marketplace/` references;
* whether unrelated `project` strings were intentionally left unchanged.

## Native Platform Identifier Verification

Confirm Android/iOS/etc. identifiers were not intentionally changed.

## Dependency Resolution

Report:

```text
flutter pub get
```

result and whether `pubspec.lock` changed.

## Formatting

Report:

```text
dart format lib test
```

result.

## Static Analysis

Report:

```text
flutter analyze
```

result.

## Tests

Report:

```text
flutter test
```

result.

## Documentation

Confirm creation of:

```text
documentation/decisions/ADR-002-flutter-package-identity.md
documentation/cursor/004_flutter_project_identity_baseline.md
```

## Security Verification

Report whether any secret/environment credential material was introduced.

## Git Status

Provide final:

```text
git status --short
```

## Issues / Warnings

If none:

```text
None.
```

## Final Statement

State whether the Flutter package identity baseline is complete and whether the repository is ready for ChatGPT review before architecture bootstrap.

Do NOT begin the Flutter architecture bootstrap.

Do NOT begin TASK 005.

Start TASK 004 now.
````

## Pre-Task Repository State

Detected Git repository root:

```text
D:/freelance/erfankhan_cse489/final
```

Current branch: `main`

Pre-task `git status --short` produced no output (clean working tree).

Pre-task `git status`:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

Latest commits:

```text
da48e9b repository_foundation_and_secret_safety
e274239 epository_documentation_bootstrap
0597ffb flutter create project cmd
```

`git ls-files project/pubspec.lock` returned:

```text
project/pubspec.lock
```

The lockfile was tracked.

Package identity before change:

```text
Dart package: project
Description: A new Flutter project.
Flutter directory: project/
Android namespace/application ID: com.example.project
Dart import: package:project/main.dart
```

Inspected files included `project/pubspec.yaml`, `project/lib/main.dart`, `project/test/widget_test.dart`, `project/README.md`, `project/android/app/build.gradle.kts`, `project/android/app/src/main/AndroidManifest.xml`, and iOS/macOS/Linux/Windows identifier locations.

The only Dart `package:project/` import was in `project/test/widget_test.dart`. Native identifiers using `com.example.project` were recorded and left unchanged.

## Work Performed

1. Verified a clean checkpoint, Git root, branch, recent commits, and tracked `project/pubspec.lock`.
2. Recorded current Dart package identity versus physical directory and native platform identifiers.
3. Changed `project/pubspec.yaml` name to `home_cleaning_marketplace` and updated the description.
4. Updated the generated widget test import to `package:home_cleaning_marketplace/main.dart`.
5. Replaced the default Flutter package README with a short package-level README.
6. Did not change Android/iOS/macOS/Linux/Windows identifiers and did not rename `project/`.
7. Ran `flutter pub get` from `project/`.
8. Ran `dart format lib test`.
9. Ran `flutter analyze` and `flutter test`.
10. Confirmed no remaining `package:project/` Dart imports.
11. Created ADR-002 and added a link in `documentation/decisions/README.md`.
12. Created this TASK 004 report.
13. Did not stage, commit, or push.

## Files Created

- `documentation/decisions/ADR-002-flutter-package-identity.md`
- `documentation/cursor/004_flutter_project_identity_baseline.md`

## Files Modified

- `project/pubspec.yaml`
- `project/test/widget_test.dart`
- `project/README.md`
- `documentation/decisions/README.md`

## Files Deleted

None.

## Commands Executed

```text
git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -3 --oneline
git ls-files project/pubspec.lock
Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
Select-String / git show for package-identity inspection
flutter pub get
git diff -- project/pubspec.lock
git status --short
dart format lib test
flutter analyze
flutter test
git status --short
git diff -- project/pubspec.yaml
git diff -- project/lib/
git diff -- project/test/
git diff -- project/README.md
git diff -- project/android/
git diff -- project/ios/
git diff --stat -- documentation/
```

Editor write operations were used for authorized file updates. `git add`, `git commit`, `git push`, `flutter pub add`, and `flutter pub upgrade` were not run.

Final `flutter analyze` and `flutter test` re-runs are recorded in Verification Results.

## Implementation Details

Dart package identity is now `home_cleaning_marketplace`. The physical Flutter directory remains `project/`.

The only Dart package-import change was:

```dart
import 'package:home_cleaning_marketplace/main.dart';
```

The generated counter UI in `project/lib/main.dart` was not redesigned. Native platform identifiers remain `com.example.project` and related generated defaults. That mismatch is documented in ADR-002 and is intentional until a later identifier decision.

## Technical Decisions

- Change only Dart package identity and imports now, while the app is still the generated counter template, to reduce later rename churn.
- Keep directory name `project/` unchanged, matching the existing repository layout.
- Leave `com.example.project` and other native identifiers unchanged because no organization/domain identity has been selected.

## Verification Performed

- Clean-checkpoint Git commands
- Tracked-lockfile check via `git ls-files project/pubspec.lock`
- Search for `package:project/` before and after
- Inspection of Android `namespace`/`applicationId` and iOS bundle identifier configuration
- `flutter pub get`
- Lockfile change check
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `git diff` of `pubspec.yaml`, `lib/`, `test/`, package README, Android, iOS, and documentation
- Secret-pattern check of TASK 004 files

## Verification Results

Starting working tree was clean. `project/pubspec.lock` was tracked.

`pubspec.yaml` now contains:

```yaml
name: home_cleaning_marketplace
description: "Flutter mobile client for the Home Cleaning Service Marketplace."
```

Version, SDK constraint, dependencies, and Material configuration were unchanged.

`package:project/` remaining after the change: none.

New package import:

```dart
import 'package:home_cleaning_marketplace/main.dart';
```

Unrelated uses of the folder name `project/` and native `com.example.project` identifiers were left unchanged.

`git diff -- project/lib/` was empty. `git diff -- project/android/` and `git diff -- project/ios/` were empty.

`flutter pub get`:

```text
Got dependencies!
4 packages have newer versions incompatible with dependency constraints.
```

`pubspec.lock` did not change.

`dart format lib test`:

```text
Formatted 2 files (0 changed) in 0.00 seconds.
```

`flutter analyze` (including final re-run after this report was created):

```text
No issues found!
```

`flutter test` (including final re-run after this report was created):

```text
00:00 +1: All tests passed!
```

One test ran and passed (Counter increments smoke test).

## Errors / Warnings

`flutter pub get` reported four packages with newer versions incompatible with current constraints (`material_color_utilities`, `meta`, `test_api`, `vector_math`). `flutter pub upgrade` was not run, as required.

## Security / Secrets Check

This task did not introduce, expose, move, or modify credentials or secrets.

No `.env` file, MongoDB URI, MongoDB credentials, API keys, tokens, passwords, or private keys were added.

## Git Diff Summary

Tracked modifications:

* `project/pubspec.yaml` — package name and description only
* `project/test/widget_test.dart` — package import only
* `project/README.md` — replaced generated Flutter README
* `documentation/decisions/README.md` — added ADR-002 link

Untracked additions:

* `documentation/decisions/ADR-002-flutter-package-identity.md`
* `documentation/cursor/004_flutter_project_identity_baseline.md`

No Android/iOS/native identifier diffs. No `pubspec.lock` diff. No `lib/` diff.

## Final Repository State

Branch remains `main`. TASK 004 changes are unstaged and uncommitted.

Dart package identity is `home_cleaning_marketplace`. Flutter directory remains `project/`. Native platform identifiers remain generated defaults.

## Unresolved Issues

Native platform identifiers remain deferred (`com.example.project` and related generated IDs), as documented in ADR-002.

## Suggested Next Step

After ChatGPT review of this uncommitted identity baseline, the next scoped task can begin Flutter architecture bootstrap.
