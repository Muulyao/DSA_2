import ballerina/kafka;
import ballerina/log;

listener kafka:Listener internationalDeliveryListener = new ("localhost:9092", "international-delivery");

service on internationalDeliveryListener {
    remote function onMessage(kafka:ConsumerRecord[] records) returns error? {
        foreach var record in records {
            log:printInfo("International Delivery Received: " + record.value.toString());
            // Add custom logic for international delivery processing
        }
    }
}

