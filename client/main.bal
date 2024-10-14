import ballerina/http;
import ballerina/log;

public function main() returns error? {
    http:Client logisticsClient = check new ("http://localhost:8080");

    json requestPayload = {
        "orderId": "12345",
        "deliveryType": "standard",
        "customerInfo": { "name": "John Doe", "address": "123 Elm St" }
    };

    var response = logisticsClient->post("/logistics/request", requestPayload);
    if (response is http:Response) {
        log:printInfo("Response: " + response.getTextPayload());
    } else {
        log:printError("Error: ", response);
    }
}
