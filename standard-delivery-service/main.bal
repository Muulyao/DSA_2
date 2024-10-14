import ballerina/http; 
import ballerinax/mongodb; 
import ballerina/log; 
import ballerina/uuid; 

string mongodbUri = "mongodb://localhost:27017";  // Update with your actual MongoDB URI

// Create the connection configuration
mongodb:ConnectionConfig mongoConfig = {
 uri: mongodbUri
,connection: {}};

// Create the MongoDB client
mongodb:Client mongoClient = check new (mongoConfig);
listener http:Listener httpListener = new(8083);

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

type Customer record {
    string firstName;
    string lastName;
    string contactNumber;
};

type Shipment record {
    string id;
    string shipmentId;
    string customerId;
    string deliveryDate;
    string timeSlot;
    string pickupLocation;
    string deliveryLocation;
    string driverName;
    string status;
};

service /standard on httpListener {

    // Handle standard delivery requests
    resource function post delivery(http:Caller caller, http:Request req) returns error? {
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
            "status": "pending" // You can set the initial status as "pending" or whatever is appropriate
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

    // Track standard delivery status
    resource function get status(http:Caller caller, http:Request req) returns error? {
        string? deliveryId = req.getQueryParamValue("deliveryId");
        if deliveryId is string {
            // Find the delivery status in MongoDB
            var standardDeliveries = mongoClient->getDatabase("logisticsDB")->getCollection("standard_deliveries");
            var result = standardDeliveries->findOne({ "deliveryId": deliveryId });

            if result is map<anydata> {
                check caller->respond(result);
            } else {
                check caller->respond({ "message": "No such standard delivery found." });
            }
        } else {
            check caller->respond({ "message": "Missing deliveryId query parameter." });
        }
    }
}

service /customer on httpListener {

    // Add customer details to the database
    resource function post add(http:Caller caller, http:Request req) returns error? {
        json requestPayload = check req.getJsonPayload();
        Customer customer = check requestPayload.cloneWithType(Customer);

        var customers = mongoClient->getDatabase("logisticsDB")->getCollection("customers");
        check customers->insert({
            "firstName": customer.firstName,
            "lastName": customer.lastName,
            "contactNumber": customer.contactNumber
        });

        check caller->respond({ "message": "Customer added successfully" });
    }

    // Retrieve customer details from the database
    resource function get info(http:Caller caller, http:Request req) returns error? {
        string? customerId = req.getQueryParamValue("customerId");

        if customerId is string {
            var customers = mongoClient->getDatabase("logisticsDB")->getCollection("customers");
            var result = customers->findOne({ "_id": customerId });

            if result is map<anydata> {
                check caller->respond(result);
            } else {
                check caller->respond({ "message": "No customer found with this ID." });
            }
        } else {
            check caller->respond({ "message": "Missing customerId query parameter." });
        }
    }
}

service /shipment on httpListener {

    // Add shipment details to the database
    resource function post add(http:Caller caller, http:Request req) returns error? {
        json requestPayload = check req.getJsonPayload();
        Shipment shipment = check requestPayload.cloneWithType(Shipment);

        var shipments = mongoClient->getDatabase("logisticsDB")->getCollection("shipments");
        check shipments->insert({
            "id": shipment.id,
            "shipmentId": shipment.shipmentId,
            "customerId": shipment.customerId,
            "deliveryDate": shipment.deliveryDate,
            "timeSlot": shipment.timeSlot,
            "pickupLocation": shipment.pickupLocation,
            "deliveryLocation": shipment.deliveryLocation,
            "driverName": shipment.driverName,
            "status": shipment.status
        });

        check caller->respond({ "message": "Shipment added successfully" });
    }

    // Retrieve shipment status from the database
    resource function get status(http:Caller caller, http:Request req) returns error? {
        string? shipmentId = req.getQueryParamValue("shipmentId");

        if shipmentId is string {
            var shipments = mongoClient->getDatabase("logisticsDB")->getCollection("shipments");
            var result = shipments->findOne({ "shipmentId": shipmentId });

            if result is map<anydata> {
                check caller->respond(result);
            } else {
                check caller->respond({ "message": "No shipment found with this ID." });
            }
        } else {
            check caller->respond({ "message": "Missing shipmentId query parameter." });
        }
    }
}

public function main() returns error? {
    log:printInfo("Logistics services started...");
}
