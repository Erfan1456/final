# Repository Layout

This document describes the current Git repository layout for the Home Cleaning Service Marketplace. It records the distinction between the Git repository root and the Flutter package root. It does not claim that application features, backend code, or a final architecture have already been implemented.

## Repository roots

Git repository root:

```text
D:\freelance\erfankhan_cse489\final
```

Flutter package root:

```text
D:\freelance\erfankhan_cse489\final\project
```

These are not the same directory. Git operations belong at the repository root. Flutter commands belong in `project/`.

## Current structure and responsibilities

```text
final/
├── documentation/
├── project/
├── README.md
└── .gitignore
```

### `project/`

Flutter/Dart mobile application. This is the current Flutter package root (`pubspec.yaml` lives here). Platform folders such as Android, iOS, web, Windows, Linux, and macOS remain inside this package.

### `documentation/`

Technical documentation and Cursor task history. Architecture, setup, database, API, feature, decision, and workflow documents belong here as they are written.

### Root README

Repository entry documentation (`README.md` at the Git root). It describes the product direction, technology baseline, layout, how to run the current Flutter project, documentation locations, and security rules.

### Root `.gitignore`

Repository-wide security and local-development ignore policy. It protects secrets, environment files, OS/editor artifacts, logs, and generated Dart/Flutter state. The nested Flutter package also has its own `project/.gitignore`.

## Future backend sibling

A later task is expected to add a Dart backend as a sibling of `project/`, conceptually:

```text
final/
├── documentation/
├── project/
└── <future Dart backend directory>
```

No backend directory exists yet. Its final name and internal structure have not been decided.

## Why the nested Flutter package is preserved in TASK 002

The existing nested Flutter package is being kept in `project/` rather than moved during TASK 002 because:

* the repository already exists in this layout;
* moving it would create unnecessary churn before architecture is decided;
* tooling can operate correctly by running Flutter commands from `project/`.
