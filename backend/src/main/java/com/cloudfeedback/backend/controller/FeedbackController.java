package com.cloudfeedback.backend.controller;

import com.cloudfeedback.backend.model.Feedback;
import com.cloudfeedback.backend.service.FeedbackService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * FeedbackController
 *
 * REST API für Feedback
 */
@RestController
@RequestMapping("/api/feedback")
public class FeedbackController {

    private final FeedbackService feedbackService;

    public FeedbackController(FeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @PostMapping
    public Feedback createFeedback(@RequestBody Feedback feedback) {
        return feedbackService.createFeedback(feedback);
    }

    @GetMapping
    public List<Feedback> getAllFeedback() {
        return feedbackService.getAllFeedback();
    }

    /**
     * Statistik der letzten 7 Tage
     */
    @GetMapping("/stats")
    public Map<String, Integer> getStats() {
        return feedbackService.getFeedbackStatsLast7Days();
    }
}