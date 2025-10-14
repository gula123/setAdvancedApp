package com.example.demo.resolver;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import com.example.demo.annotations.TableName;
import io.awspring.cloud.dynamodb.DynamoDbTableNameResolver;

@Component
public class CustomTableNameResolver implements DynamoDbTableNameResolver {

    private static final Logger logger = LoggerFactory.getLogger(CustomTableNameResolver.class);
    private final Environment environment;

    public CustomTableNameResolver(Environment environment) {
        this.environment = environment;
    }

    @Override
    public <T> String resolve(Class<T> clazz) {
        logger.debug("Resolving table name for class: {}", clazz.getName());
        
        TableName tableNameAnnotation = clazz.getAnnotation(TableName.class);
        
        if (tableNameAnnotation != null) {
            // Get the actual table name from the property specified in the annotation
            String propertyName = tableNameAnnotation.propertyName();
            String tableName = environment.getProperty(propertyName);
            
            logger.debug("Property '{}' resolved to: '{}'", propertyName, tableName);
            
            if (tableName != null) {
                logger.info("Resolved table name '{}' for class {}", tableName, clazz.getSimpleName());
                return tableName;
            }
            
            throw new IllegalStateException("Property '" + propertyName + "' not found for table mapping of class " + clazz.getName());
        }
        
        // Fallback to class name in lowercase for classes without annotation
        String fallbackName = clazz.getSimpleName().toLowerCase();
        logger.debug("Using fallback table name '{}' for class {}", fallbackName, clazz.getSimpleName());
        return fallbackName;
    }
}
