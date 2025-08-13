FROM openjdk:17-jdk
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} discovery.jar
ENTRYPOINT ["java","-jar","discovery.jar"]
EXPOSE 9001
