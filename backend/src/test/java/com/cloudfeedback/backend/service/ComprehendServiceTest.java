package com.cloudfeedback.backend.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import software.amazon.awssdk.services.comprehend.ComprehendClient;
import software.amazon.awssdk.services.comprehend.model.*;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ComprehendServiceTest {

    private ComprehendClient comprehendClient;
    private ComprehendService comprehendService;

    @BeforeEach
    void setUp() {
        comprehendClient = mock(ComprehendClient.class);
        comprehendService = new ComprehendService(comprehendClient);
    }

    @Test
    void detectSentiment_buildsCorrectRequest_andCallsClient() {

        // Arrange
        DetectSentimentResponse mockResponse = DetectSentimentResponse.builder()
                .sentiment("POSITIVE")
                .build();

        when(comprehendClient.detectSentiment(any(DetectSentimentRequest.class)))
                .thenReturn(mockResponse);

        // Act
        DetectSentimentResponse result = comprehendService.detectSentiment("Test Text");

        // Assert response passt durch
        assertEquals("POSITIVE", result.sentimentAsString());

        // Request capturen
        ArgumentCaptor<DetectSentimentRequest> captor = ArgumentCaptor.forClass(DetectSentimentRequest.class);

        verify(comprehendClient, times(1))
                .detectSentiment(captor.capture());

        DetectSentimentRequest capturedRequest = captor.getValue();

        assertEquals("Test Text", capturedRequest.text());
        assertEquals(LanguageCode.DE, capturedRequest.languageCode());
    }

    @Test
    void detectKeyPhrases_buildsCorrectRequest_andCallsClient() {

        // Arrange
        DetectKeyPhrasesResponse mockResponse = DetectKeyPhrasesResponse.builder()
                .keyPhrases(List.of())
                .build();

        when(comprehendClient.detectKeyPhrases(any(DetectKeyPhrasesRequest.class)))
                .thenReturn(mockResponse);

        // Act
        comprehendService.detectKeyPhrases("Noch ein Test");

        // Request capturen
        ArgumentCaptor<DetectKeyPhrasesRequest> captor = ArgumentCaptor.forClass(DetectKeyPhrasesRequest.class);

        verify(comprehendClient, times(1))
                .detectKeyPhrases(captor.capture());

        DetectKeyPhrasesRequest capturedRequest = captor.getValue();

        assertEquals("Noch ein Test", capturedRequest.text());
        assertEquals(LanguageCode.DE, capturedRequest.languageCode());
    }

    @Test
    void extractKeyPhrasesAsString_joinsTextsCorrectly() {

        KeyPhrase p1 = KeyPhrase.builder().text("Hallo").build();
        KeyPhrase p2 = KeyPhrase.builder().text("Welt").build();

        String result = comprehendService.extractKeyPhrasesAsString(List.of(p1, p2));

        assertEquals("Hallo, Welt", result);
    }

    @Test
    void extractKeyPhrasesAsString_withEmptyList_returnsEmptyString() {

        String result = comprehendService.extractKeyPhrasesAsString(List.of());

        assertEquals("", result);
    }
}
