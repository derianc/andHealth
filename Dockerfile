# ---- Build stage ----
FROM dart:3.9.2 AS build

WORKDIR /app

# Copy pubspec first for dependency resolution
COPY pubspec.* ./
RUN dart pub get

# Copy rest of the source code
COPY . .

# Compile your Dart app into a native executable
RUN dart compile exe bin/andhealth.dart -o /app/andhealth

# ---- Runtime stage ----
FROM debian:bookworm-slim AS runtime

# Copy the compiled binary from the build stage
COPY --from=build /app/andhealth /bin/andhealth

# Expose a port (update if your app binds to something else)
EXPOSE 8080

# Start the app
CMD ["/bin/andhealth"]
