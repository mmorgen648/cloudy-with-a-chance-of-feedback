package com.cloudfeedback.backend.service;

import com.cloudfeedback.backend.model.Feedback;
import com.cloudfeedback.backend.repository.FeedbackRepository;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.comprehend.model.DetectSentimentResponse;
import software.amazon.awssdk.services.comprehend.model.DetectKeyPhrasesResponse;

import java.util.List;

/**
 * FeedbackService
 *
 * Zweck:
 * - Speichert Feedback
 * - Führt ML Analyse durch
 */
@Service
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final ComprehendService comprehendService;

    public FeedbackService(FeedbackRepository feedbackRepository,
                           ComprehendService comprehendService) {
        this.feedbackRepository = feedbackRepository;
        this.comprehendService = comprehendService;
    }

    /**
     * Speichert Feedback + analysiert Sentiment & KeyPhrases
     */
    public Feedback createFeedback(Feedback feedback) {

        // 1️⃣ Sentiment analysieren
DetectSentimentResponse sentimentResponse =
        comprehendService.detectSentiment(feedback.getText());

feedback.setSentiment(sentimentResponse.sentimentAsString());

var score = sentimentResponse.sentimentScore();

String confidenceJson = String.format(
        java.util.Locale.US,
        "{\"positive\":%f,\"negative\":%f,\"neutral\":%f,\"mixed\":%f}",
        score.positive(),
        score.negative(),
        score.neutral(),
        score.mixed()
);


feedback.setConfidenceJson(confidenceJson);

// 2️⃣ KeyPhrases extrahieren
DetectKeyPhrasesResponse keyResponse =
        comprehendService.detectKeyPhrases(feedback.getText());

String keyPhrasesJson = keyResponse.keyPhrases().stream()
        .map(p -> "\"" + p.text() + "\"")
        .reduce((a, b) -> a + "," + b)
        .map(s -> "[" + s + "]")
        .orElse("[]");

feedback.setKeyPhrasesJson(keyPhrasesJson);


        // 3️⃣ Speichern
        return feedbackRepository.save(feedback);
    }

    public List<Feedback> getAllFeedback() {
        return feedbackRepository.findAll();
    }
}
