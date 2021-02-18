FROM openjdk:15-slim as builder
RUN mkdir src
COPY . /src
WORKDIR /src
RUN ./mvnw clean package -DskipTests --quiet

FROM openjdk:15-alpine
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=builder /src/target /build
WORKDIR /build
EXPOSE 8090
ENTRYPOINT ["java", "-jar", "FagkveldTestApi-0.0.1-SNAPSHOT.jar"]