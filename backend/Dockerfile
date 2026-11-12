# ---------- Stage 1: build the JAR from the Maven source code ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom.xml first and download dependencies (cached between builds)
COPY pom.xml .
RUN mvn -q -B dependency:go-offline

# Copy the source code and build the executable JAR (tests need a database, so skip them here)
COPY src ./src
RUN mvn -q -B -DskipTests package

# ---------- Stage 2: run the JAR in a small Java runtime image ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]