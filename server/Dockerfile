# Container image for Google Cloud Run (or any container host).
# Build from the repository root, because the server uses the shared
# packages/ebucard_models package:
#
#   docker build -f server/Dockerfile -t ebucard-server .

FROM dart:stable AS build
WORKDIR /app
COPY packages/ebucard_models packages/ebucard_models
COPY server server
WORKDIR /app/server
RUN dart pub global activate dart_frog_cli \
 && dart pub get \
 && dart pub global run dart_frog_cli:dart_frog build \
 && dart compile exe build/bin/server.dart -o build/bin/server

# Minimal runtime: the compiled server, its runtime libraries and the CA
# certificates needed for outgoing HTTPS (Apple/Google keys, breach check,
# Cloud Storage, SMTP over TLS).
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /app/server/build/bin/server /app/bin/server
ENV HOST=0.0.0.0
EXPOSE 8080
CMD ["/app/bin/server"]
