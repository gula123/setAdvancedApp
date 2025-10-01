package com.example.demo.resolver;

import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import com.example.demo.annotations.TableName;
import io.awspring.cloud.dynamodb.DynamoDbTableNameResolver;

@Component
public class CustomTableNameResolver implements DynamoDbTableNameResolver {

    private final Environment environment;

    public CustomTableNameResolver(Environment environment) {
        this.environment = environment;
    }

    @Override
    public <T> String resolve(Class<T> clazz) {
        TableName tableNameAnnotation = clazz.getAnnotation(TableName.class);
        
        if (tableNameAnnotation != null) {
            // Get the actual table name from the property specified in the annotation
            String propertyName = tableNameAnnotation.propertyName();
            String tableName = environment.getProperty(propertyName);
            
            if (tableName != null) {
                return tableName;
            }
            
            throw new IllegalStateException("Property '" + propertyName + "' not found for table mapping of class " + clazz.getName());
        }
        
        // Fallback to class name in lowercase for classes without annotation
        return clazz.getSimpleName().toLowerCase();
    }
}
