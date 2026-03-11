package com.cloudfeedback.backend.service;

import com.cloudfeedback.backend.model.Feedback;
import com.cloudfeedback.backend.repository.FeedbackRepository;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.comprehend.model.DetectSentimentResponse;
import software.amazon.awssdk.services.comprehend.model.DetectKeyPhrasesResponse;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

                DetectSentimentResponse sentimentResponse = comprehendService.detectSentiment(feedback.getText());

                feedback.setSentiment(sentimentResponse.sentimentAsString());

                var score = sentimentResponse.sentimentScore();

                String confidenceJson = String.format(
                                java.util.Locale.US,
                                "{\"positive\":%f,\"negative\":%f,\"neutral\":%f,\"mixed\":%f}",
                                score.positive(),
                                score.negative(),
                                score.neutral(),
                                score.mixed());

                feedback.setConfidenceJson(confidenceJson);

                DetectKeyPhrasesResponse keyResponse = comprehendService.detectKeyPhrases(feedback.getText());

                String keyPhrasesJson = keyResponse.keyPhrases().stream()
                                .map(p -> "\"" + p.text() + "\"")
                                .reduce((a, b) -> a + "," + b)
                                .map(s -> "[" + s + "]")
                                .orElse("[]");

                feedback.setKeyPhrasesJson(keyPhrasesJson);

                return feedbackRepository.save(feedback);
        }

        public List<Feedback> getAllFeedback() {
                return feedbackRepository.findAll();
        }

        /**
         * Statistik der letzten 7 Tage
         */
        public Map<String, Integer> getFeedbackStatsLast7Days() {

                LocalDateTime sevenDaysAgo = LocalDateTime.now().minusDays(7);

                List<Feedback> feedbacks = feedbackRepository.findByCreatedAtAfter(sevenDaysAgo);

                int positive = 0;
                int negative = 0;
                int neutral = 0;
                int mixed = 0;

                for (Feedback f : feedbacks) {

                        if (f.getSentiment() == null)
                                continue;

                        switch (f.getSentiment()) {
                                case "POSITIVE" -> positive++;
                                case "NEGATIVE" -> negative++;
                                case "NEUTRAL" -> neutral++;
                                case "MIXED" -> mixed++;
                        }
                }

                Map<String, Integer> result = new HashMap<>();

                result.put("positive", positive);
                result.put("negative", negative);
                result.put("neutral", neutral);
                result.put("mixed", mixed);

                return result;
        }
}