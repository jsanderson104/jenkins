# Use the same base image from your command
FROM docker.io/jenkins/jenkins:latest

# Expose the ports specified in your -p flags
EXPOSE 8080
EXPOSE 8443

# Define the volume path
VOLUME /var/jenkins_home
