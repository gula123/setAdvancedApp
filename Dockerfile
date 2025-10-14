# Simple Dockerfile for Spring Boot app
FROM amazoncorretto:21

# Set working directory
WORKDIR /app

# Copy the jar file (build it first with: mvn clean package)
COPY target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]