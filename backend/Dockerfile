# syntax=docker/dockerfile:1

# Multi-stage production image for the Dart Frog API.
# Secrets must be injected at runtime — never bake .env into the image.

FROM dart:stable AS build
WORKDIR /app

# Resolve dependencies first for better layer caching.
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub global activate dart_frog_cli \
 && dart pub global run dart_frog_cli:dart_frog build \
 && dart compile exe build/bin/server.dart -o build/bin/server

FROM debian:bookworm-slim AS runtime
RUN useradd --create-home --uid 10001 appuser \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/bin/server /app/bin/server

USER appuser
ENV PORT=8080
EXPOSE 8080

# Compiled server includes repository-owned Dart Frog custom entrypoint
# (backend/main.dart): validates PORT before bind (absent→8080; invalid→exit 1).
# Bind address remains Dart Frog generated InternetAddress.anyIPv6 (all interfaces).
CMD ["/app/bin/server"]
