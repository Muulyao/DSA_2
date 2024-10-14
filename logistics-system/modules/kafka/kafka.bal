import ballerinax/kafka;

public function createProducer() returns kafka:Producer|error {
    kafka:ProducerConfiguration producerConfigs = {
        clientId: "logistics-producer",
        acks: "all",
        retryCount: 3
    };
    return new (kafka:DEFAULT_URL, producerConfigs);
}

public function createConsumer(string groupId, string[] topics) returns kafka:Consumer|error {
    kafka:ConsumerConfiguration consumerConfigs = {
        groupId: groupId,
        topics: topics,
        pollingInterval: 1
    };
    return new (kafka:DEFAULT_URL, consumerConfigs);
}