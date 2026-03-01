package com.cloudfeedback.backend.service;

import com.cloudfeedback.backend.model.Feedback;
import com.cloudfeedback.backend.repository.FeedbackRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import software.amazon.awssdk.services.comprehend.model.DetectKeyPhrasesResponse;
import software.amazon.awssdk.services.comprehend.model.DetectSentimentResponse;
import software.amazon.awssdk.services.comprehend.model.KeyPhrase;
import software.amazon.awssdk.services.comprehend.model.SentimentScore;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class FeedbackServiceTest {

    private FeedbackRepository feedbackRepository;
    private ComprehendService comprehendService;
    private FeedbackService feedbackService;

    @BeforeEach
    void setUp() {
        feedbackRepository = mock(FeedbackRepository.class);
        comprehendService = mock(ComprehendService.class);
        feedbackService = new FeedbackService(feedbackRepository, comprehendService);
    }

    @Test
    void createFeedback_setsSentiment() {

        Feedback feedback = new Feedback();
        feedback.setText("Great product!");

        DetectSentimentResponse sentimentResponse = DetectSentimentResponse.builder()
                .sentiment("POSITIVE")
                .sentimentScore(SentimentScore.builder()
                        .positive(0.9f)
                        .negative(0.05f)
                        .neutral(0.03f)
                        .mixed(0.02f)
                        .build())
                .build();

        DetectKeyPhrasesResponse keyResponse = DetectKeyPhrasesResponse.builder()
                .keyPhrases(List.of())
                .build();

        when(comprehendService.detectSentiment(any()))
                .thenReturn(sentimentResponse);

        when(comprehendService.detectKeyPhrases(any()))
                .thenReturn(keyResponse);

        when(feedbackRepository.save(any()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Feedback result = feedbackService.createFeedback(feedback);

        assertEquals("POSITIVE", result.getSentiment());
    }

    @Test
    void createFeedback_setsConfidenceJsonCorrectly() {

        Feedback feedback = new Feedback();
        feedback.setText("Great product!");

        SentimentScore score = SentimentScore.builder()
                .positive(0.9f)
                .negative(0.05f)
                .neutral(0.03f)
                .mixed(0.02f)
                .build();

        DetectSentimentResponse sentimentResponse = DetectSentimentResponse.builder()
                .sentiment("POSITIVE")
                .sentimentScore(score)
                .build();

        DetectKeyPhrasesResponse keyResponse = DetectKeyPhrasesResponse.builder()
                .keyPhrases(List.of())
                .build();

        when(comprehendService.detectSentiment(any()))
                .thenReturn(sentimentResponse);

        when(comprehendService.detectKeyPhrases(any()))
                .thenReturn(keyResponse);

        when(feedbackRepository.save(any()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Feedback result = feedbackService.createFeedback(feedback);

        String expectedJson = "{\"positive\":0.900000,\"negative\":0.050000,\"neutral\":0.030000,\"mixed\":0.020000}";

        assertEquals(expectedJson, result.getConfidenceJson());
    }

    @Test
    void createFeedback_setsKeyPhrasesJsonCorrectly() {

        Feedback feedback = new Feedback();
        feedback.setText("Great product!");

        SentimentScore score = SentimentScore.builder()
                .positive(1f)
                .negative(0f)
                .neutral(0f)
                .mixed(0f)
                .build();

        DetectSentimentResponse sentimentResponse = DetectSentimentResponse.builder()
                .sentiment("POSITIVE")
                .sentimentScore(score)
                .build();

        KeyPhrase phrase1 = KeyPhrase.builder().text("Great").build();
        KeyPhrase phrase2 = KeyPhrase.builder().text("product").build();

        DetectKeyPhrasesResponse keyResponse = DetectKeyPhrasesResponse.builder()
                .keyPhrases(List.of(phrase1, phrase2))
                .build();

        when(comprehendService.detectSentiment(any()))
                .thenReturn(sentimentResponse);

        when(comprehendService.detectKeyPhrases(any()))
                .thenReturn(keyResponse);

        when(feedbackRepository.save(any()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Feedback result = feedbackService.createFeedback(feedback);

        assertEquals("[\"Great\",\"product\"]", result.getKeyPhrasesJson());
    }

    @Test
    void createFeedback_returnsSavedEntity() {

        Feedback feedback = new Feedback();
        feedback.setText("Test");

        SentimentScore score = SentimentScore.builder()
                .positive(1f)
                .negative(0f)
                .neutral(0f)
                .mixed(0f)
                .build();

        DetectSentimentResponse sentimentResponse = DetectSentimentResponse.builder()
                .sentiment("POSITIVE")
                .sentimentScore(score)
                .build();

        DetectKeyPhrasesResponse keyResponse = DetectKeyPhrasesResponse.builder()
                .keyPhrases(List.of())
                .build();

        when(comprehendService.detectSentiment(any()))
                .thenReturn(sentimentResponse);

        when(comprehendService.detectKeyPhrases(any()))
                .thenReturn(keyResponse);

        when(feedbackRepository.save(any()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Feedback result = feedbackService.createFeedback(feedback);

        assertSame(feedback, result);
    }

    @Test
    void getAllFeedback_returnsRepositoryResult() {

        List<Feedback> mockList = List.of(new Feedback(), new Feedback());

        when(feedbackRepository.findAll()).thenReturn(mockList);

        List<Feedback> result = feedbackService.getAllFeedback();

        assertEquals(2, result.size());
        verify(feedbackRepository, times(1)).findAll();
    }
}