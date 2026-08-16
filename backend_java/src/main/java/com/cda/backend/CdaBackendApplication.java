package com.cda.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CdaBackendApplication {

    public static void main(String[] args) {
        System.out.println("🚀 Starting Cranes Digital Academy Java Backend Service...");
        SpringApplication.run(CdaBackendApplication.class, args);
        System.out.println("✅ Java Backend Service is LIVE on http://localhost:8080");
    }
}
