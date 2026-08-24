# Documentation

This directory is the central technical documentation repository for the Home Cleaning Service Marketplace.

Documentation here is intended to grow alongside the product. It records Cursor development work, architecture, setup, database design, APIs, features, engineering decisions, and workflows. Nothing in this tree implies that a given architecture, backend, database, API, or product feature has already been implemented.

Documentation must evolve together with the implementation. A feature is not considered fully documented if its implementation changes but its corresponding documentation remains outdated.

## Documentation areas

### `cursor/`

Stores the historical record of Cursor development tasks.

Each Cursor task must eventually have its own numbered report describing the prompt, objective, files changed, commands executed, verification, and related outcomes.

### `architecture/`

Stores system architecture documentation, diagrams, module relationships, application layering, component responsibilities, and major structural explanations.

Current documents:

* [repository-layout.md](architecture/repository-layout.md)

### `setup/`

Stores environment setup and development setup instructions, such as Flutter, Dart, Android Studio, MongoDB Atlas, backend setup, environment variables, and local execution instructions.

Current documents:

* [development-environment.md](setup/development-environment.md)

### `database/`

Stores MongoDB architecture, collections, schemas/models, indexes, relationships/references, validation rules, migrations or migration-equivalent strategies, and database decisions.

### `api/`

Stores backend API documentation including endpoints, requests, responses, validation, authentication requirements, errors, and API conventions.

### `features/`

Stores documentation explaining how each product feature works technically and functionally.

### `decisions/`

Stores important technical decisions and the reasoning behind them.

Current documents:

* [ADR-001-initial-stack-and-repository-layout.md](decisions/ADR-001-initial-stack-and-repository-layout.md)

### `workflows/`

Stores development, testing, Git, release, deployment, and other engineering workflows.

Current documents:

* [cursor-development-workflow.md](workflows/cursor-development-workflow.md)
