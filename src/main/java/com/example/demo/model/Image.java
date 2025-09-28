package com.example.demo.model;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.UUID;

import com.example.demo.annotations.TableName;

import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbPartitionKey;

@DynamoDbBean
@TableName(name = "images")
public class Image {
  private UUID id;
  private String objectPath;
  private String objectSize;
  private LocalDateTime timeAdded;
  private LocalDateTime timeUpdated;
  private Set<String> labels;

  private Status status;

  public Status getStatus() {
    return status;
  }

  public void setStatus(Status status) {
    this.status = status;
  }

  @DynamoDbPartitionKey
  public UUID getId() {
    return id;
  }

  public void setId(UUID id) {
    this.id = id;
  }

  public String getObjectPath() {
    return objectPath;
  }

  public void setObjectPath(String objectPath) {
    this.objectPath = objectPath;
  }

  public String getObjectSize() {
    return objectSize;
  }

  public void setObjectSize(String objectSize) {
    this.objectSize = objectSize;
  }

  public LocalDateTime getTimeAdded() {
    return timeAdded;
  }

  public void setTimeAdded(LocalDateTime timeAdded) {
    this.timeAdded = timeAdded;
  }

  public LocalDateTime getTimeUpdated() {
    return timeUpdated;
  }

  public void setTimeUpdated(LocalDateTime timeUpdated) {
    this.timeUpdated = timeUpdated;
  }

  public Set<String> getLabels() {
    return labels;
  }

  public void setLabels(Set<String> labels) {
    this.labels = labels;
  }
}
