package com.example.demo.resolver;

import org.springframework.stereotype.Component;

import com.example.demo.annotations.TableName;
import io.awspring.cloud.dynamodb.DynamoDbTableNameResolver;

@Component
public class CustomTableNameResolver implements DynamoDbTableNameResolver {

    @Override
    public <T> String resolve(Class<T> clazz) {
        return clazz.getAnnotation(TableName.class).name();
    }
}
