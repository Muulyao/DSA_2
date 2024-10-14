# Start with the Ballerina base image
FROM ballerina/ballerina:latest

# Copy the Ballerina code into the container
COPY . /home/ballerina

# Set the working directory
WORKDIR /home/ballerina

# Build the Ballerina service
RUN bal build main.bal

# Expose the necessary port (8080 for HTTP, or Kafka related ports)
EXPOSE 8080

# Run the Ballerina service
CMD ["bal", "run", "main.bal"]
