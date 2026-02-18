package com.cloudfeedback.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Feedback Entity
 *
 * Repräsentiert ein Kundenfeedback in der Datenbank.
 *
 * Tabelle: feedback
 */
@Entity
@Table(name = "feedback")
public class Feedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Text des Kunden
    @Column(nullable = false, length = 2000)
    private String text;

    // Zeitpunkt der Erstellung
    private LocalDateTime createdAt;

    // Sentiment (POSITIVE, NEGATIVE, etc.)
    private String sentiment;

    // Confidence Scores als JSON String
    @Column(length = 2000)
    private String confidenceJson;

    // Key Phrases als JSON String
    @Column(length = 2000)
    private String keyPhrasesJson;

    // Wird automatisch vor dem Speichern gesetzt
    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }

    // ===== Getter & Setter =====

    public Long getId() { return id; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }

    public LocalDateTime getCreatedAt() { return createdAt; }

    public String getSentiment() { return sentiment; }
    public void setSentiment(String sentiment) { this.sentiment = sentiment; }

    public String getConfidenceJson() { return confidenceJson; }
    public void setConfidenceJson(String confidenceJson) { this.confidenceJson = confidenceJson; }

    public String getKeyPhrasesJson() { return keyPhrasesJson; }
    public void setKeyPhrasesJson(String keyPhrasesJson) { this.keyPhrasesJson = keyPhrasesJson; }
}
