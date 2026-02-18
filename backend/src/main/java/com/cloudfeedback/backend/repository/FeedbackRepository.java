package com.cloudfeedback.backend.repository;

import com.cloudfeedback.backend.model.Feedback;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * FeedbackRepository
 *
 * Stellt CRUD-Operationen für Feedback bereit.
 */
public interface FeedbackRepository extends JpaRepository<Feedback, Long> {
}
