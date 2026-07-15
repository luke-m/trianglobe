# syntax=docker/dockerfile:1
# Single production image: the Vite build is baked into the Spring Boot jar's
# static resources, so one container serves both the frontend and the API.

# --- Stage 1: frontend build (discarded after the build) ---
FROM node:22-alpine AS frontend
WORKDIR /build
# Copy ONLY the dependency manifests first: as long as they don't change,
# Docker reuses the cached npm ci layer on every rebuild.
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# --- Stage 2: backend build (discarded after the build) ---
FROM eclipse-temurin:21-jdk-alpine AS backend
WORKDIR /build
COPY backend/mvnw backend/pom.xml ./
COPY backend/.mvn .mvn
# Same caching trick, Maven edition: download dependencies against pom.xml
# only, so source edits don't re-download the world.
RUN ./mvnw -q dependency:go-offline
COPY backend/src src
# The wiring: Vite's output becomes static resources inside the jar.
COPY --from=frontend /build/dist src/main/resources/static
# Tests run in CI before any image is built; the image build just packages.
RUN ./mvnw -q package -DskipTests

# --- Stage 3: runtime (the only stage that ships) ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
USER app
COPY --from=backend /build/target/*.jar app.jar
ENTRYPOINT [ "java", "-jar", "app.jar" ]
EXPOSE 8080