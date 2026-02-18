package com.cloudfeedback.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * TestController
 *
 * Zweck:
 * - Einfacher Test-Endpoint
 * - Prüft ob REST-API korrekt funktioniert
 *
 * URL:
 * GET /api/test
 */
@RestController
public class TestController {

    /**
     * Test-Endpunkt
     *
     * @return String - einfache Bestätigung
     */
    @GetMapping("/api/test")
    public String test() {
        return "Backend läuft 🚀";
    }
}
