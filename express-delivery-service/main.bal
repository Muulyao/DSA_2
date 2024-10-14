import ballerina/kafka;
import ballerina/log;

listener kafka:Listener expressDeliveryListener = new ("localhost:9092", "express-delivery");

service on expressDeliveryListener {
    remote function onMessage(kafka:ConsumerRecord[] records) returns error? {
        foreach var record in records {
            log:printInfo("Express Delivery Received: " + record.value.toString());
            // Add custom logic for express delivery processing
        }
    }
}
