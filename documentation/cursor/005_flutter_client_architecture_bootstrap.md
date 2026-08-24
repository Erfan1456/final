# Cursor Task 005 — Flutter Client Architecture Bootstrap

## Metadata

- Task ID: 005
- Task title: Flutter Client Architecture Bootstrap
- Date: 2026-08-24 18:35 +06:00
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Establish the permanent Flutter client architecture before product features: install the approved Riverpod, go_router, and Dio packages; replace the generated counter app with a Riverpod-bootstrapped application shell, routing, theme, non-secret configuration, Dio infrastructure, and a foundation screen; add architecture-appropriate tests and documentation; leave all changes uncommitted.

## Exact Cursor Prompt

````text
# TASK 005 — Flutter Client Architecture Bootstrap

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
└── project/                  ← Flutter application root
```

Flutter/Dart package identity:

```text
home_cleaning_marketplace
```

Physical Flutter directory:

```text
project/
```

Do NOT rename that directory.

---

# PURPOSE OF TASK 005

TASK 005 establishes the permanent Flutter client architecture before product features begin.

This task must:

1. verify TASK 004 has been committed and the repository starts clean;
2. select and install the approved Flutter architecture dependencies;
3. replace the generated counter application with the real application bootstrap;
4. establish app-level routing;
5. establish state-management/dependency-injection infrastructure;
6. establish the application theme boundary;
7. establish non-secret runtime configuration infrastructure;
8. establish HTTP client infrastructure without calling a backend;
9. establish the initial feature-oriented folder structure through real files only;
10. create a simple foundation screen proving the architecture boots correctly;
11. replace the counter widget test with architecture-appropriate tests;
12. document the architecture and technical decisions;
13. run formatting, static analysis, and tests;
14. create the TASK 005 Cursor report;
15. leave everything uncommitted for ChatGPT review.

This task establishes infrastructure only.

Do NOT begin authentication, booking, cleaner search, MongoDB integration, or other marketplace features.

---

# APPROVED ARCHITECTURE DECISIONS

The Flutter client will use a:

```text
feature-oriented layered architecture
```

with these conceptual responsibilities:

```text
UI / Presentation
        ↓
View Models / State
        ↓
Repositories
        ↓
Services
        ↓
External API / platform
```

For sufficiently complex features, an optional domain/use-case layer may later sit between presentation and repositories.

Do NOT create a domain layer everywhere merely for ceremony.

---

# APPROVED THIRD-PARTY PACKAGES

Install these dependencies:

```text
flutter_riverpod: ^3.4.2
go_router: ^17.5.0
dio: ^5.11.0
```

Their responsibilities are:

### `flutter_riverpod`

* application state management;
* view-model state;
* asynchronous state;
* dependency injection;
* test overrides.

### `go_router`

* declarative navigation;
* route hierarchy;
* future deep linking;
* future authentication/role redirects.

### `dio`

* HTTP transport;
* request/response configuration;
* future interceptors;
* cancellation/timeouts;
* future API communication with the Dart backend.

Do NOT install:

* hooks_riverpod;
* provider;
* bloc;
* flutter_bloc;
* get;
* get_it;
* injectable;
* auto_route;
* retrofit;
* freezed;
* json_serializable;
* build_runner;
* riverpod_generator;
* riverpod_annotation;
* custom_lint;
* riverpod_lint;
* logger;
* dotenv;
* any MongoDB Flutter package.

Those may be evaluated later only if actually needed.

---

# ARCHITECTURE PRINCIPLES

TASK 005 must establish and document the following rules.

## 1. Feature-oriented organization

Product functionality should ultimately live under:

```text
lib/features/<feature>/
```

rather than placing every repository in one global folder and every screen in another global folder.

A mature feature may eventually resemble:

```text
features/
└── authentication/
    ├── data/
    │   ├── models/
    │   ├── repositories/
    │   └── services/
    ├── presentation/
    │   ├── views/
    │   ├── view_models/
    │   └── widgets/
    └── domain/               ← optional, only when justified
        └── use_cases/
```

Do NOT create this authentication structure now.

It is an architectural example only.

---

## 2. Views remain thin

Flutter widgets/views should primarily:

* render state;
* collect user input;
* forward user actions;
* perform UI/layout/animation logic.

Business/data logic must not accumulate in widgets.

---

## 3. View models own presentation logic

Future feature view models will:

* expose screen state;
* respond to UI commands;
* call repositories;
* transform repository data for presentation.

With Riverpod, asynchronous feature view models may later use:

```text
AsyncNotifier
```

and synchronous view models may use:

```text
Notifier
```

when appropriate.

Do not create fake view models simply to demonstrate Riverpod.

---

## 4. Repositories are application data sources of truth

Repositories will:

* coordinate services;
* provide application/domain data;
* manage data-related business rules;
* handle caching/retries where appropriate;
* expose stable abstractions to view models.

Feature views must not call Dio directly.

---

## 5. Services wrap external data sources

Services will eventually wrap:

* REST API endpoints;
* platform services;
* local storage;
* other external integrations.

Services should not contain presentation state.

---

## 6. Optional domain/use-case layer

Use cases are allowed later when logic:

* combines multiple repositories;
* becomes complex;
* is reused across view models.

Do NOT require one use-case for every trivial repository method.

---

## 7. `core/` is cross-cutting only

`core/` should contain infrastructure genuinely shared across features, such as:

* configuration;
* networking;
* generic error infrastructure;
* shared foundational utilities.

Feature-specific business code does NOT belong in `core/`.

---

## 8. Dependency direction

Dependencies should generally flow inward/downward:

```text
View
 ↓
View Model
 ↓
Repository abstraction
 ↓
Repository implementation
 ↓
Service
 ↓
External system
```

Lower layers must not import feature presentation classes.

---

# STRICT SAFETY RULES

For TASK 005:

1. Do NOT implement sign up.
2. Do NOT implement login.
3. Do NOT implement logout.
4. Do NOT implement password recovery.
5. Do NOT implement user roles.
6. Do NOT implement customer screens.
7. Do NOT implement cleaner screens.
8. Do NOT implement admin screens.
9. Do NOT implement bookings.
10. Do NOT implement payments.
11. Do NOT implement messaging.
12. Do NOT implement reviews.
13. Do NOT connect to MongoDB.
14. Do NOT create MongoDB credentials.
15. Do NOT create `.env`.
16. Do NOT place MongoDB URI anywhere in Flutter.
17. Do NOT create backend code.
18. Do NOT create a backend directory.
19. Do NOT select the Dart backend framework.
20. Do NOT change Android application ID.
21. Do NOT change Android namespace.
22. Do NOT change iOS/macOS/native identifiers.
23. Do NOT rename `project/`.
24. Do NOT add packages other than the three approved dependencies.
25. Do NOT add code-generation infrastructure.
26. Do NOT add fake repositories merely to populate folders.
27. Do NOT create empty directories solely to make a large-looking architecture.
28. Do NOT create placeholder feature folders for unimplemented features.
29. Do NOT make actual HTTP requests.
30. Do NOT add authentication interceptors yet.
31. Do NOT add token handling.
32. Do NOT log HTTP request bodies.
33. Do NOT hard-code secrets.
34. Do NOT stage changes.
35. Do NOT commit.
36. Do NOT push.
37. Do NOT modify historical TASK 001–004 reports.
38. Do NOT make unrelated platform/configuration changes.

---

# STEP 1 — VERIFY CLEAN STARTING STATE

Before changing anything, run:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -4 --oneline
```

Expected Git root:

```text
D:\freelance\erfankhan_cse489\final
```

Expected branch:

```text
main
```

Expected starting working tree:

```text
clean
```

If:

```bash
git status --short
```

produces any output, STOP.

Do not modify anything.

Verify:

```text
project/pubspec.yaml
project/pubspec.lock
project/lib/main.dart
project/test/widget_test.dart
```

exist before TASK 005.

Confirm current package name remains:

```text
home_cleaning_marketplace
```

---

# STEP 2 — RECORD PRE-TASK FLUTTER HEALTH

From:

```text
project/
```

run:

```bash
flutter pub get
flutter analyze
flutter test
```

TASK 005 must begin from a healthy Flutter baseline.

Expected before changes:

```text
flutter analyze → no issues
flutter test    → counter smoke test passes
```

If the baseline fails before TASK 005 changes:

STOP.

Do not try to redesign the application.

Report the pre-existing failure.

---

# STEP 3 — INSTALL ONLY THE APPROVED DEPENDENCIES

From:

```text
project/
```

run:

```bash
flutter pub add flutter_riverpod:^3.4.2
flutter pub add go_router:^17.5.0
flutter pub add dio:^5.11.0
```

If your shell requires quoting, use an equivalent safe syntax.

Do NOT run:

```bash
flutter pub upgrade
```

Do NOT install any other package.

After installation, inspect:

```text
project/pubspec.yaml
project/pubspec.lock
```

Report the actual resolved versions.

If one of the approved versions cannot resolve against the current Flutter/Dart SDK:

STOP and report the dependency conflict.

Do not silently substitute another package or major version.

---

# STEP 4 — CREATE THE PERMANENT INITIAL SOURCE STRUCTURE

Transform `project/lib/` into this initial structure:

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── app_routes.dart
│   └── theme/
│       └── app_theme.dart
│
├── core/
│   ├── config/
│   │   └── app_config.dart
│   └── network/
│       └── dio_provider.dart
│
└── features/
    └── foundation/
        └── presentation/
            └── foundation_screen.dart
```

Do NOT create unused directories such as:

```text
data/
domain/
repositories/
services/
models/
use_cases/
```

inside the foundation feature.

Do NOT create empty architecture folders just to match future examples.

Directories should appear as functionality requires them.

---

# STEP 5 — REPLACE `main.dart`

Replace the generated counter bootstrap in:

```text
project/lib/main.dart
```

with a minimal application entry point.

Responsibilities:

1. import Flutter;
2. import Riverpod;
3. import the real app widget;
4. call:

```dart
WidgetsFlutterBinding.ensureInitialized();
```

5. run the app inside:

```dart
ProviderScope
```

Conceptually:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: HomeCleaningMarketplaceApp(),
    ),
  );
}
```

Use the real package/import paths.

Do not place routing, theme definitions, state, or feature UI directly in `main.dart`.

`main.dart` should remain extremely small.

---

# STEP 6 — CREATE THE ROOT APP WIDGET

Create:

```text
project/lib/app/app.dart
```

Create a root widget named:

```text
HomeCleaningMarketplaceApp
```

It should be a Riverpod-aware widget only where necessary.

Use:

```text
MaterialApp.router
```

not:

```text
MaterialApp(home: ...)
```

Configure:

* product title;
* router configuration;
* light theme;
* dark theme;
* system theme mode;
* `debugShowCheckedModeBanner: false`.

Do not place business logic in this class.

---

# STEP 7 — CREATE ROUTE CONSTANTS

Create:

```text
project/lib/app/router/app_routes.dart
```

Provide a small centralized route definition structure.

For TASK 005 there is only one real route:

```text
/
```

for the foundation screen.

Use clear constants rather than scattering route strings.

For example, an abstract/final utility type or equivalent may expose:

```text
foundationPath
foundationName
```

Do not create routes for:

* login;
* signup;
* customer;
* cleaner;
* admin;
* booking;
* profile;

because those features do not exist yet.

Do not add fake redirects.

---

# STEP 8 — CREATE THE ROUTER

Create:

```text
project/lib/app/router/app_router.dart
```

Use:

```text
go_router
```

and expose the router through Riverpod.

Create something conceptually equivalent to:

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    ...
  );
});
```

Register only the foundation route.

The foundation route should render:

```text
FoundationScreen
```

Do NOT implement authentication redirect logic yet.

Do NOT implement role redirects.

Do NOT implement nested navigation.

Do NOT implement bottom navigation.

Do NOT implement deep-link business behavior yet.

This task only establishes a router boundary that can grow later.

---

# STEP 9 — CREATE APPLICATION THEME BOUNDARY

Create:

```text
project/lib/app/theme/app_theme.dart
```

Establish:

```text
light theme
dark theme
Material 3
```

Do not build the final visual design system yet.

Use a simple temporary Material seed color or default Material-compatible approach.

Clearly comment/document that detailed branding is deferred.

Avoid scattering colors/styles throughout the foundation screen.

The purpose of this file is architectural centralization, not final design.

Do NOT add third-party font packages.

Do NOT download fonts.

---

# STEP 10 — CREATE NON-SECRET APP CONFIGURATION

Create:

```text
project/lib/core/config/app_config.dart
```

This configuration exists for **public/non-secret runtime configuration only**.

Provide an `AppConfig` abstraction containing:

```text
apiBaseUrl
```

Read it using:

```dart
String.fromEnvironment('API_BASE_URL')
```

or an equivalent compile-time Dart environment mechanism.

For TASK 005:

* an absent `API_BASE_URL` must NOT prevent the app from starting;
* it may default to an empty string;
* no HTTP request will be performed.

Also expose:

```text
hasApiBaseUrl
```

or an equivalent helper if useful.

Expose `AppConfig` using Riverpod so it can later be overridden in tests/environments.

Example conceptual behavior:

```text
API_BASE_URL supplied → use it
API_BASE_URL absent   → app still starts
```

IMPORTANT:

`API_BASE_URL` is not a secret.

However:

```text
MongoDB URI
passwords
tokens
private credentials
```

must NEVER be placed in this Flutter configuration.

Do NOT use `flutter_dotenv`.

Do NOT create `.env`.

---

# STEP 11 — CREATE DIO INFRASTRUCTURE

Create:

```text
project/lib/core/network/dio_provider.dart
```

Expose a Riverpod provider that constructs the shared Dio client.

Configure sensible foundational options such as:

* `baseUrl` from `AppConfig`;
* connection timeout;
* receive timeout;
* send timeout;
* `Accept: application/json`.

Keep the configuration conservative.

Do not add request logging.

Do not add bearer tokens.

Do not add authentication interceptors.

Do not add refresh-token logic.

Do not make a network request.

Do not create feature API services yet.

Document in code/comments only where useful that future feature services should depend on this transport layer rather than constructing arbitrary Dio instances throughout the codebase.

---

# STEP 12 — CREATE THE FOUNDATION SCREEN

Create:

```text
project/lib/features/foundation/presentation/foundation_screen.dart
```

This is NOT a product feature.

It only proves:

* app bootstrap works;
* routing works;
* theme works;
* feature organization works.

Keep the UI intentionally simple.

A `Scaffold` may contain centered content such as:

```text
Home Cleaning Service Marketplace
Foundation ready
```

Optionally include a standard Material icon.

Do not make it look like a finished landing page.

Do not add buttons for unimplemented routes.

Do not add login/signup cards.

Do not add mock cleaner data.

Do not add booking UI.

Do not add fake navigation.

Do not create a view model for this screen because it has no logic/state requiring one.

This absence should be intentional and documented.

---

# STEP 13 — REMOVE THE GENERATED COUNTER APPLICATION

Ensure the generated counter-specific implementation is gone from `lib/`.

There should no longer be:

* `MyHomePage`;
* `_MyHomePageState`;
* `_counter`;
* `_incrementCounter`;
* counter button;
* generated counter explanatory text.

Do not merely hide the counter route.

Remove the template application code cleanly.

---

# STEP 14 — REPLACE THE GENERATED TEST

The current:

```text
project/test/widget_test.dart
```

tests the Flutter counter.

Remove or replace that counter-specific test.

Prefer renaming/replacing it with:

```text
project/test/app/app_smoke_test.dart
```

Create directories as needed.

The test must verify at minimum that:

1. the app can be pumped inside its required ProviderScope;
2. router initialization succeeds;
3. the foundation screen is rendered;
4. these strings are visible:

```text
Home Cleaning Service Marketplace
Foundation ready
```

The test must not access a real network.

No mock backend is required.

If you delete:

```text
project/test/widget_test.dart
```

record the deletion accurately.

---

# STEP 15 — ADD A CONFIGURATION UNIT TEST

Create:

```text
project/test/core/config/app_config_test.dart
```

Test behavior that does not depend on machine-specific real secrets.

At minimum test explicitly constructed configurations, for example:

```text
empty API base URL → hasApiBaseUrl == false
non-empty API base URL → hasApiBaseUrl == true
```

Design `AppConfig` so such construction is testable without needing actual environment variables.

Do not place real URLs/credentials into tests.

A harmless example URL such as:

```text
https://example.invalid
```

may be used.

---

# STEP 16 — DO NOT OVERENGINEER ERROR HANDLING YET

Do NOT create unused:

```text
AppException
Result
Failure
Either
NetworkError
RepositoryException
```

abstractions during TASK 005.

Those should be introduced when a real service/repository requires them.

Architecture infrastructure should grow because of actual requirements, not speculative boilerplate.

---

# STEP 17 — DOCUMENT THE FLUTTER CLIENT ARCHITECTURE

Create:

```text
documentation/architecture/flutter-client-architecture.md
```

Document:

## Architecture Goals

* scalability;
* maintainability;
* testability;
* clear dependency boundaries;
* feature isolation;
* avoiding business logic in widgets.

## High-Level Flow

```text
View
  ↓
View Model
  ↓
Repository
  ↓
Service
  ↓
Dart backend API
```

Explain that domain/use-case objects may be inserted when justified.

## Folder Strategy

Document:

```text
lib/app/
lib/core/
lib/features/
```

and their responsibilities.

Document the future feature-level layered example, while clearly stating folders are created only as needed.

## State Management

Explain Riverpod's responsibilities.

## Routing

Explain go_router's responsibilities.

## Networking

Explain Dio's responsibility.

Explain strongly:

```text
Flutter never directly accesses MongoDB Atlas.
```

## Dependency Rules

Explain allowed/forbidden dependencies between layers.

## Testing Strategy

Describe future:

* service tests;
* repository tests;
* view-model tests;
* widget/view tests;
* integration tests.

## Domain Layer Policy

Explain domain/use-case layer is optional and added only when justified.

## Current State

State that TASK 005 contains only infrastructure and a foundation screen.

Do not claim marketplace features are implemented.

---

# STEP 18 — CREATE ADR-003

Create:

```text
documentation/decisions/ADR-003-flutter-client-architecture.md
```

Use:

```text
# ADR-003 — Flutter Client Architecture

## Status
## Context
## Decision
## Alternatives Considered
## Consequences
## Deferred Decisions
```

### Status

```text
Accepted
```

### Context

Explain that the application will grow across Customer, Cleaner, and Administrator functionality and requires testable boundaries before those features are implemented.

### Decision

Record:

```text
Feature-oriented layered organization
Riverpod for state management and dependency injection
go_router for navigation
Dio for HTTP transport
Repository/service separation
Optional domain/use-case layer
```

### Alternatives Considered

At minimum discuss:

#### Global layer-first organization

Example:

```text
lib/screens/
lib/models/
lib/repositories/
lib/services/
```

Not selected as the primary structure because large applications can become difficult to navigate when code for one feature is spread throughout the project.

#### BLoC

Viable but not selected because Riverpod supplies both state management and dependency injection with less architectural duplication for this project.

#### Provider/ChangeNotifier only

Viable for simpler applications, but Riverpod was selected for scalable dependency composition, async-state handling, test overrides, and avoiding BuildContext dependency.

#### GetIt service locator

Not selected because Riverpod will already provide dependency management and introducing a second DI system is unnecessary.

#### Direct `Navigator` calls everywhere

Not selected because centralized declarative routing is more appropriate for future deep links and authentication/role redirection.

#### Flutter `http` package

Viable, but Dio selected for richer request configuration, cancellation, interceptors, and future authentication/error-handling requirements.

### Consequences

Include advantages and tradeoffs:

* several architecture concepts must be learned;
* packages become project dependencies;
* feature boundaries remain clear;
* testing and dependency replacement become easier;
* future role-aware routing is supported;
* Dio must remain below presentation/repository boundaries;
* unnecessary layers should still be avoided.

### Deferred Decisions

Include:

* authentication flow;
* token storage;
* secure storage package;
* role-based routing;
* local database/cache;
* offline mode;
* JSON/model code generation;
* API error/result model;
* analytics;
* push notifications;
* final UI design system.

---

# STEP 19 — UPDATE DOCUMENTATION INDEXES

Update only as necessary:

```text
documentation/architecture/README.md
documentation/decisions/README.md
documentation/README.md
```

Add concise links to:

```text
architecture/flutter-client-architecture.md
decisions/ADR-003-flutter-client-architecture.md
```

Do not rewrite unrelated documentation.

---

# STEP 20 — UPDATE FLUTTER PACKAGE README

Update:

```text
project/README.md
```

only enough to reflect that the Flutter architecture foundation now exists.

Mention:

* Riverpod;
* go_router;
* Dio;
* major `lib/` directories;
* that no backend/product features exist yet;
* that `API_BASE_URL` is public runtime configuration, not a secret.

Do NOT include a MongoDB connection string.

Do NOT claim authentication or API integration exists.

---

# STEP 21 — FORMAT

From:

```text
project/
```

run:

```bash
dart format lib test
```

Record which files were changed.

---

# STEP 22 — RUN STATIC ANALYSIS

Run:

```bash
flutter analyze
```

It must complete successfully.

Do not suppress warnings merely to make analysis green.

Fix only legitimate TASK 005 issues.

---

# STEP 23 — RUN TESTS

Run:

```bash
flutter test
```

All tests must pass.

Expected tests should now include:

* application/foundation smoke test;
* AppConfig unit tests.

There should no longer be a counter-specific test.

Report the exact number of tests that ran.

---

# STEP 24 — VERIFY DEPENDENCY RULES AND SOURCE STATE

Search for:

```text
MyHomePage
_incrementCounter
_counter
package:project/
```

They should no longer remain in active Dart application/test code.

Search for MongoDB-like connection strings:

```text
mongodb://
mongodb+srv://
```

None should exist in Flutter source/configuration/documentation created by TASK 005.

Verify no real:

```text
.env
```

was created.

---

# STEP 25 — VERIFY NETWORK IS NOT USED YET

Search the new source for actual invocations such as:

```text
dio.get
dio.post
dio.put
dio.patch
dio.delete
```

There should be no real application API request in TASK 005.

The Dio provider should exist only as infrastructure.

---

# STEP 26 — REVIEW EXACT CHANGES

From repository root run:

```bash
git status --short
git diff -- project/pubspec.yaml
git diff -- project/pubspec.lock
git diff -- project/lib/
git diff -- project/test/
git diff -- project/README.md
git diff -- project/android/
git diff -- project/ios/
git diff -- documentation/
```

Confirm:

* only approved packages were added;
* counter application was replaced;
* no Android/iOS changes occurred;
* no native IDs changed;
* no backend was created;
* no secret file was created;
* documentation changes are within TASK 005 scope.

---

# STEP 27 — CREATE TASK 005 REPORT

Create:

```text
documentation/cursor/005_flutter_client_architecture_bootstrap.md
```

Use:

```text
documentation/cursor/task-report-template.md
```

The report MUST contain the complete exact TASK 005 prompt under:

```text
## Exact Cursor Prompt
```

Accurately document:

* clean starting Git state;
* starting Flutter health;
* packages added;
* resolved package versions;
* files created;
* files modified;
* files deleted;
* source architecture;
* main/bootstrap behavior;
* router;
* theme;
* app configuration;
* Dio provider;
* foundation screen;
* removed counter template;
* tests created;
* documentation created/modified;
* commands run;
* formatting;
* `flutter analyze`;
* `flutter test`;
* dependency verification;
* secret/security checks;
* final Git status;
* unresolved issues.

Do not record secret values.

---

# STEP 28 — FINAL VERIFICATION AFTER REPORT CREATION

Because the report itself changes the repository, perform the final verification again:

```bash
git status --short
git diff -- project/android/
git diff -- project/ios/
```

From `project/` run again:

```bash
flutter analyze
flutter test
```

The final reported results must correspond to the repository after the TASK 005 report and documentation exist.

---

# STEP 29 — DO NOT COMMIT

Do NOT run:

```bash
git add
git commit
git push
```

Leave TASK 005 completely uncommitted for ChatGPT review.

---

# FINAL RESPONSE FORMAT

Respond with exactly these top-level sections:

# TASK 005 RESULT

## Status

Use one:

```text
SUCCESS
PARTIAL
FAILED
```

## Pre-Task Verification

Report:

* Git root;
* branch;
* starting working-tree state;
* latest commit;
* starting `flutter analyze`;
* starting `flutter test`.

## Dependencies Added

Report exact requested and resolved versions for:

```text
flutter_riverpod
go_router
dio
```

Confirm no other direct dependency was added.

## Final Source Structure

Show the resulting:

```text
project/lib/
```

tree.

## Architecture Bootstrap

Summarize:

* `main.dart`;
* root app;
* Riverpod bootstrap;
* router;
* theme;
* configuration;
* Dio infrastructure;
* foundation feature.

## Counter Template Removal

Confirm all counter-specific app code was removed.

## Runtime Configuration

Report how:

```text
API_BASE_URL
```

works and confirm it is not treated as a secret.

## Networking Verification

Confirm:

* Dio infrastructure exists;
* no HTTP request is performed;
* no MongoDB connection exists.

## Tests

List test files and report the final:

```text
flutter test
```

result and number of tests.

## Static Analysis

Report final:

```text
flutter analyze
```

result.

## Files Created

List all files created by TASK 005.

## Files Modified

List all files modified by TASK 005.

## Files Deleted

List all files deleted by TASK 005.

## Documentation

Confirm creation of:

```text
documentation/architecture/flutter-client-architecture.md
documentation/decisions/ADR-003-flutter-client-architecture.md
documentation/cursor/005_flutter_client_architecture_bootstrap.md
```

## Security Verification

Report whether any:

* `.env`;
* MongoDB URI;
* credential;
* API key;
* token;
* password;
* private key

was introduced.

## Native Platform Verification

Report whether Android/iOS/native project configuration changed.

## Git Status

Provide final:

```text
git status --short
```

## Issues / Warnings

Report all relevant warnings.

If none:

```text
None.
```

## Final Statement

State whether the Flutter client architecture bootstrap is complete and ready for ChatGPT review.

Do NOT implement authentication.

Do NOT begin TASK 006.

Start TASK 005 now.
````

## Pre-Task Repository State

Detected Git repository root:

```text
D:/freelance/erfankhan_cse489/final
```

Current branch: `main`

Pre-task working tree was clean.

Latest commits:

```text
181255b flutter_project_identity_baseline
da48e9b repository_foundation_and_secret_safety
e274239 epository_documentation_bootstrap
0597ffb flutter create project cmd
```

Package name was `home_cleaning_marketplace`. Required files existed, including `project/test/widget_test.dart`.

Pre-task Flutter health from `project/`:

* `flutter pub get` — Got dependencies
* `flutter analyze` — No issues found
* `flutter test` — Counter increments smoke test passed (`+1: All tests passed!`)

## Work Performed

1. Verified a clean TASK 004 checkpoint and healthy Flutter baseline.
2. Installed only `flutter_riverpod`, `go_router`, and `dio` via `flutter pub add`.
3. Replaced the counter `main.dart` with a `ProviderScope` bootstrap.
4. Added application shell, route constants, go_router provider, Material 3 theme boundary, `AppConfig`, Dio provider, and foundation screen.
5. Deleted the counter widget test and added smoke plus `AppConfig` tests.
6. Documented architecture and ADR-003, and updated indexes plus `project/README.md`.
7. Formatted, analyzed, and tested.
8. Created this report.
9. Did not stage, commit, or push.

## Files Created

- `project/lib/app/app.dart`
- `project/lib/app/router/app_router.dart`
- `project/lib/app/router/app_routes.dart`
- `project/lib/app/theme/app_theme.dart`
- `project/lib/core/config/app_config.dart`
- `project/lib/core/network/dio_provider.dart`
- `project/lib/features/foundation/presentation/foundation_screen.dart`
- `project/test/app/app_smoke_test.dart`
- `project/test/core/config/app_config_test.dart`
- `documentation/architecture/flutter-client-architecture.md`
- `documentation/decisions/ADR-003-flutter-client-architecture.md`
- `documentation/cursor/005_flutter_client_architecture_bootstrap.md`

## Files Modified

- `project/pubspec.yaml`
- `project/pubspec.lock`
- `project/lib/main.dart`
- `project/README.md`
- `documentation/README.md`
- `documentation/architecture/README.md`
- `documentation/decisions/README.md`

## Files Deleted

- `project/test/widget_test.dart`

## Commands Executed

```text
git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -4 --oneline
Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
git ls-files project/pubspec.lock project/pubspec.yaml project/lib/main.dart project/test/widget_test.dart
flutter pub get
flutter analyze
flutter test
flutter pub add "flutter_riverpod:^3.4.2"
flutter pub add "go_router:^17.5.0"
flutter pub add "dio:^5.11.0"
dart format lib test
flutter analyze
flutter test
tree /F project\lib
git status --short
git diff -- project/android/
git diff -- project/ios/
git diff -- project/pubspec.yaml
```

Editor write operations created/updated source and documentation. `git add`, `git commit`, `git push`, and `flutter pub upgrade` were not run.

Final post-report `flutter analyze` and `flutter test` are recorded in Verification Results.

## Implementation Details

`main.dart` only ensures Flutter bindings and runs `HomeCleaningMarketplaceApp` inside `ProviderScope`.

`HomeCleaningMarketplaceApp` is a `ConsumerWidget` that watches `appRouterProvider` and builds `MaterialApp.router` with light/dark Material 3 themes and `ThemeMode.system`.

`AppRoutes` exposes `foundationPath` (`/`) and `foundationName`. `appRouterProvider` registers only that route to `FoundationScreen`. There is no authentication or role redirect.

`AppConfig` holds public `apiBaseUrl` from `String.fromEnvironment('API_BASE_URL')`, defaulting to empty so the app starts without it. `hasApiBaseUrl` is true only when the trimmed value is non-empty. `appConfigProvider` exposes this for later test/environment overrides.

`dioProvider` builds a shared Dio client from `AppConfig` with 15-second timeouts and `Accept: application/json`. It does not log, attach tokens, or send requests.

`FoundationScreen` is a thin presentation widget with no view model, because it has no presentation logic.

## Technical Decisions

- Install the three approved packages only; `flutter pub add` wrote exact resolved versions `3.4.2`, `17.5.0`, and `5.11.0` into `pubspec.yaml`.
- Create folders only where real files exist. The foundation feature has presentation only.
- Do not add a view model, repositories, services, or error-type hierarchy for the foundation screen.
- Treat `API_BASE_URL` as public compile-time configuration, not a secret.

## Verification Performed

- Clean Git checkpoint and required-file checks
- Pre-task `flutter pub get`, `flutter analyze`, `flutter test`
- Package install and `pubspec.yaml` / lock inspection
- Searches for counter remnants, `package:project/`, `mongodb://`, `mongodb+srv://`, Dio request methods, and `.env`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `git diff` of Android/iOS/`pubspec.yaml`

## Verification Results

Requested vs resolved direct dependencies:

```text
flutter_riverpod  requested ^3.4.2   resolved 3.4.2
go_router         requested ^17.5.0  resolved 17.5.0
dio               requested ^5.11.0  resolved 5.11.0
```

No other direct dependency was added. `cupertino_icons` remains from the generated template.

`dart format lib test`:

```text
Formatted 10 files (5 changed)
```

Changed by format: `app_config.dart`, `dio_provider.dart`, `foundation_screen.dart`, `main.dart`, `app_smoke_test.dart`.

First post-implementation `flutter analyze`: `No issues found!`

First post-implementation `flutter test`: `All tests passed!` — 4 tests (1 smoke + 3 AppConfig).

Final post-report `flutter analyze`: `No issues found!`

Final post-report `flutter test`: `All tests passed!` — 4 tests.

Counter identifiers and `package:project/` were not found in Dart application/test code. No MongoDB URI strings. No `.env`. No `dio.get` / `post` / `put` / `patch` / `delete` invocations.

`git diff -- project/android/` and `git diff -- project/ios/` were empty.

## Errors / Warnings

`flutter pub get` / `flutter pub add` reported packages with newer versions incompatible with current constraints. `flutter pub upgrade` was not run.

`flutter pub add` wrote exact versions (`3.4.2`, `17.5.0`, `5.11.0`) rather than caret constraints. Those match the requested releases.

## Security / Secrets Check

This task did not introduce, expose, move, or modify credentials or secrets.

No `.env`, MongoDB URI, credential, API key, token, password, or private key was added. `API_BASE_URL` is documented as public runtime configuration.

## Git Diff Summary

`pubspec.yaml` gained the three approved direct dependencies. `pubspec.lock` was updated by `flutter pub add`. `lib/main.dart` replaced the counter template. New app/core/features source and tests were added. Counter `widget_test.dart` was deleted. Documentation indexes, architecture document, ADR-003, and this report were added. No Android/iOS diffs.

## Final Repository State

Branch remains `main`. TASK 005 changes are unstaged and uncommitted. The Flutter client architecture bootstrap exists; product features are not implemented.

## Unresolved Issues

Native platform identifiers remain `com.example.project` (ADR-002). Backend framework, authentication, and API integration remain deferred.

## Suggested Next Step

After ChatGPT review of this uncommitted architecture bootstrap, a later scoped task can begin a real product feature or backend foundation.
