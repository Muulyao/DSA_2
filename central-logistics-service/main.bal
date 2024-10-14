import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerinax/mongodb;

// MongoDB connection configuration
string mongodbUri = "mongodb://localhost:27017"; // Update with your actual MongoDB URI

// Create the connection configuration
mongodb:ConnectionConfig mongoConfig = {
    uri: mongodbUri
,connection: {}};

// Create the MongoDB client
mongodb:Client mongoClient = check new (mongoConfig);

// Create an HTTP listener on port 8080
listener http:Listener httpListener = new(8080);

// Type definitions for requests and responses
type StandardDeliveryRequest record {
    string origin;
    string destination;
    string customerId;
    string packageWeight;
};

type StandardDeliveryResponse record {
    string deliveryId;
    string status;
    string message;
};

type ExpressDeliveryRequest record {
    string customerId;
    string shipmentType;
    string pickupLocation;
    string deliveryLocation;
    string preferredTimeSlot;
};

type ExpressDeliveryResponse record {
    string deliveryId;
    string status;
    string message;
};

// Central Logistics Service
service /logistics on httpListener {

    // Handle standard delivery requests
    resource function post standardDelivery(http:Caller caller, http:Request req) returns error? {
        json requestPayload = check req.getJsonPayload();
        StandardDeliveryRequest standardRequest = check requestPayload.cloneWithType(StandardDeliveryRequest);
        string id = uuid:createType1AsString();

        StandardDeliveryResponse response = {
            deliveryId: id,
            status: "Standard",
            message: "Standard delivery request received."
        };

        // Prepare the document to insert into MongoDB
        map<anydata> deliveryDocument = {
            "deliveryId": id,
            "origin": standardRequest.origin,
            "destination": standardRequest.destination,
            "customerId": standardRequest.customerId,
            "packageWeight": standardRequest.packageWeight,
            "status": "pending" // Initial status
        };

        // Insert the request into the MongoDB collection
        var standardDeliveries = mongoClient->getDatabase("logisticsDB")->getCollection("standard_deliveries");
        var insertResult = standardDeliveries->insert(deliveryDocument);
        if (insertResult is error) {
            log:printError("Error inserting delivery: " + insertResult.message());
            return insertResult; // Return the error if insertion fails
        }

        check caller->respond(response);
    }

    // Handle express delivery requests
    resource function post expressDelivery(http:Caller caller, http:Request req) returns error? {
        json requestPayload = check req.getJsonPayload();
        ExpressDeliveryRequest expressRequest = check requestPayload.cloneWithType(ExpressDeliveryRequest);
        string id = uuid:createType1AsString();

        ExpressDeliveryResponse response = {
            deliveryId: id,
            status: "Express",
            message: "Express delivery request received."
        };

        // Prepare the document to insert into MongoDB
        map<anydata> deliveryDocument = {
            "deliveryId": id,
            "customerId": expressRequest.customerId,
            "shipmentType": expressRequest.shipmentType,
            "pickupLocation": expressRequest.pickupLocation,
            "deliveryLocation": expressRequest.deliveryLocation,
            "preferredTimeSlot": expressRequest.preferredTimeSlot,
            "status": "pending" // Initial status
        };

        // Insert the request into the MongoDB collection
        var expressDeliveries = mongoClient->getDatabase("logisticsDB")->getCollection("express_deliveries");
        var insertResult = expressDeliveries->insert(deliveryDocument);
        if (insertResult is error) {
            log:printError("Error inserting delivery: " + insertResult.message());
            return insertResult; // Return the error if insertion fails
        }

        check caller->respond(response);
    }

    // Track delivery status
    resource function get trackDelivery(http:Caller caller, http:Request req) returns error? {
        string? deliveryId = req.getQueryParamValue("deliveryId");
        if deliveryId is string {
            // Find the delivery status in MongoDB
            var standardDeliveries = mongoClient->getDatabase("logisticsDB")->getCollection("standard_deliveries");
            var expressDeliveries = mongoClient->getDatabase("logisticsDB")->getCollection("express_deliveries");

            var result = standardDeliveries->findOne({ "deliveryId": deliveryId });
            if result is map<anydata> {
                check caller->respond(result);
            } else {
                result = expressDeliveries->findOne({ "deliveryId": deliveryId });
                if result is map<anydata> {
                    check caller->respond(result);
                } else {
                    check caller->respond({ "message": "No delivery found with this ID." });
                }
            }
        } else {
            check caller->respond({ "message": "Missing deliveryId query parameter." });
        }
    }
}

public function main() returns error? {
    log:printInfo("Central Logistics Service started...");
}
