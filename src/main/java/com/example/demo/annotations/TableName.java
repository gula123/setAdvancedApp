package com.example.demo.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.Target;

@Target(ElementType.TYPE)
@Retention(java.lang.annotation.RetentionPolicy.RUNTIME)
public
@interface TableName {
    /**
     * The application property name that holds the actual table name.
     * For example: "app.dynamodb.table-name"
     * The resolver will lookup this property to get the actual table name.
     */
    String propertyName();
}