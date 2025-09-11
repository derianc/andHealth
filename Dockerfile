# ---- Build stage ----
FROM ghcr.io/cirruslabs/flutter:3.24.3 AS build
WORKDIR /app

# Copy pubspec first and get dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the source
COPY . .

# If you have a Flutter backend target, build it
# Example: compile a Dart server in bin/
RUN dart compile exe bin/andhealth.dart -o /app/andhealth

# ---- Runtime stage ----
FROM debian:bookworm-slim AS runtime
COPY --from=build /app/andhealth /bin/andhealth
EXPOSE 8080
CMD ["/bin/andhealth"]
