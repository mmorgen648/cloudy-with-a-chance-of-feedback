package com.cloudfeedback.backend.controller;

import com.cloudfeedback.backend.model.Feedback;
import com.cloudfeedback.backend.service.FeedbackService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
}
