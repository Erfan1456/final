# ADR-002 — Flutter Package Identity

## Status

Accepted.

## Context

The generated Flutter app used the generic package name:

```text
project
```

Leaving this in place while expanding the codebase would cause future imports to use an inappropriate generic namespace and increase rename churn later.

The application still contains only the generated counter template, so the identity change can be made with minimal churn.

## Decision

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

The human-readable product name remains:

```text
Home Cleaning Service Marketplace
```

## Scope

This ADR affects Dart package identity and package imports only.

It does not change native platform identifiers, organization/domain ownership, or store listing identity.

## Deferred Decisions

The following remain deferred because no final organization/domain identity has been selected:

* Android application ID
* Android namespace
* iOS bundle identifier
* macOS bundle identifier
* Linux application identifier
* Windows packaging/product identifiers
* organization/domain ownership
* store listing identity

The current generated platform identifier remains `com.example.project`. That mismatch with the Dart package name is deliberate until those identifiers are decided separately.

## Consequences

Future Dart imports can consistently use:

```dart
package:home_cleaning_marketplace/...
```

Native platform identifiers temporarily remain generated defaults until separately decided.

The Flutter package directory name remains `project/`, so Flutter commands continue to be run from that directory.
