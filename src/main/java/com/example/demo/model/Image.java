package com.example.demo.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set;

import com.example.demo.annotations.TableName;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbPartitionKey;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbSortKey;

@Data
@NoArgsConstructor
@AllArgsConstructor
@DynamoDbBean
@TableName(propertyName = "app.dynamodb.image-table-name")
public class Image {
    private String id;
    private String objectPath;
    private String objectSize;
    private LocalDateTime timeAdded;
    private LocalDateTime timeUpdated;
    private Set<String> labels;
    private Status status;

    @DynamoDbPartitionKey
    public String getId() {
        return id;
    }

    @DynamoDbSortKey
    public String getObjectPath() {
        return objectPath;
    }
}
