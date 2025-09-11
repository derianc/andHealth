FROM ghcr.io/cirruslabs/flutter:3.27.0 AS build
WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN dart compile exe bin/andhealth.dart -o /app/andhealth

FROM debian:bookworm-slim AS runtime
COPY --from=build /app/andhealth /bin/andhealth
EXPOSE 8080
CMD ["/bin/andhealth"]
