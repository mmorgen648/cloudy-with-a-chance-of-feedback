# ------------------------------------------------------------
# Stage 1: Build Stage (Maven + JDK 21)
# ------------------------------------------------------------
FROM maven:3.9-eclipse-temurin-21 AS build

# Arbeitsverzeichnis im Container
WORKDIR /app

# Zuerst nur pom.xml kopieren (besseres Caching)
COPY pom.xml ./

# Maven Dependencies vorladen
RUN mvn -B -q -DskipTests dependency:go-offline

# Jetzt gesamten Source-Code kopieren
COPY src ./src

# Anwendung bauen (Jar erzeugen)
RUN mvn -B -q -DskipTests package


# ------------------------------------------------------------
# Stage 2: Runtime Stage (kleines Image mit nur JRE)
# ------------------------------------------------------------
FROM eclipse-temurin:21-jre

# Sicherheitsmaßnahme: Nicht als root laufen
RUN useradd -m appuser
USER appuser

WORKDIR /app

# Gebaute Jar-Datei aus dem Build-Container übernehmen
COPY --from=build /app/target/*.jar app.jar

# Standard Spring Boot Port
EXPOSE 8080

# Startbefehl
ENTRYPOINT ["java", "-jar", "app.jar"]