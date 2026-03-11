package com.cloudfeedback.backend.service;

import org.springframework.stereotype.Service;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.comprehend.ComprehendClient;
import software.amazon.awssdk.services.comprehend.model.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * ComprehendService
 *
 * Zweck:
 * - Ruft Amazon Comprehend auf
 * - Ermittelt Sentiment
 * - Extrahiert Key Phrases
 *
 * Wichtig:
 * - Keine festen Credentials konfigurieren
 * - AWS SDK nutzt automatisch:
 * 1. lokale AWS CLI Credentials
 * 2. Environment Variables
 * 3. IAM Role (EKS / EC2)
 */
@Service
public class ComprehendService {

    private final ComprehendClient comprehendClient;

    public ComprehendService() {

        this.comprehendClient = ComprehendClient.builder()

                // Region Frankfurt (Comprehend verfügbar)
                .region(Region.EU_CENTRAL_1)

                // KEIN CredentialsProvider hier
                // AWS SDK verwendet automatisch DefaultCredentialsProvider

                .build();
    }

    public ComprehendService(ComprehendClient comprehendClient) {
        this.comprehendClient = comprehendClient;
    }

    /**
     * Analysiert Sentiment eines Textes
     */
    public DetectSentimentResponse detectSentiment(String text) {

        DetectSentimentRequest request = DetectSentimentRequest.builder()
                .text(text)
                .languageCode("de")
                .build();

        return comprehendClient.detectSentiment(request);
    }

    /**
     * Extrahiert Schlüsselbegriffe
     */
    public DetectKeyPhrasesResponse detectKeyPhrases(String text) {

        DetectKeyPhrasesRequest request = DetectKeyPhrasesRequest.builder()
                .text(text)
                .languageCode("de")
                .build();

        return comprehendClient.detectKeyPhrases(request);
    }

    /**
     * Hilfsmethode: KeyPhrases als String speichern
     */
    public String extractKeyPhrasesAsString(List<KeyPhrase> phrases) {
        return phrases.stream()
                .map(KeyPhrase::text)
                .collect(Collectors.joining(", "));
    }
}