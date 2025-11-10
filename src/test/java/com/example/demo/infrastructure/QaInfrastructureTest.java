package com.example.demo.infrastructure;

import org.springframework.test.context.ActiveProfiles;

/**
 * Infrastructure test for QA environment
 * Validates that all AWS services are properly deployed and running
 */
@ActiveProfiles("qa")
public class QaInfrastructureTest extends BaseInfrastructureTest {

    public QaInfrastructureTest() {
        super(new InfrastructureConfig(
            "qa",
            "eu-north-1",
            "setadvanced-gula-qa",
            "image-recognition-results-qa",
            "app-lb-qa",
            "s3-events-qa",
            "image-processing-queue-qa"
        ));
    }
}