package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class DetectionEvent {

    private long detectionId;
    private String gateId;
    private String direction;
    private Integer sequenceId;
    private BigDecimal distanceCm;
    private Boolean objectDetected;
    private String rawImagePath;
    private String annotatedImagePath;
    private String detectedClass;
    private BigDecimal confidence;
    private String decision;
    private String eventStatus;
    private Integer countBefore;
    private Integer countAfter;
    private String errorMessage;
    private Timestamp createdAt;

    public DetectionEvent() {
    }

    public DetectionEvent(long detectionId,
                          String gateId,
                          String direction,
                          Integer sequenceId,
                          BigDecimal distanceCm,
                          Boolean objectDetected,
                          String rawImagePath,
                          String annotatedImagePath,
                          String detectedClass,
                          BigDecimal confidence,
                          String decision,
                          String eventStatus,
                          Integer countBefore,
                          Integer countAfter,
                          String errorMessage,
                          Timestamp createdAt) {

        this.detectionId = detectionId;
        this.gateId = gateId;
        this.direction = direction;
        this.sequenceId = sequenceId;
        this.distanceCm = distanceCm;
        this.objectDetected = objectDetected;
        this.rawImagePath = rawImagePath;
        this.annotatedImagePath = annotatedImagePath;
        this.detectedClass = detectedClass;
        this.confidence = confidence;
        this.decision = decision;
        this.eventStatus = eventStatus;
        this.countBefore = countBefore;
        this.countAfter = countAfter;
        this.errorMessage = errorMessage;
        this.createdAt = createdAt;
    }

    public long getDetectionId() {
        return detectionId;
    }

    public void setDetectionId(long detectionId) {
        this.detectionId = detectionId;
    }

    public String getGateId() {
        return gateId;
    }

    public void setGateId(String gateId) {
        this.gateId = gateId;
    }

    public String getDirection() {
        return direction;
    }

    public void setDirection(String direction) {
        this.direction = direction;
    }

    public Integer getSequenceId() {
        return sequenceId;
    }

    public void setSequenceId(Integer sequenceId) {
        this.sequenceId = sequenceId;
    }

    public BigDecimal getDistanceCm() {
        return distanceCm;
    }

    public void setDistanceCm(BigDecimal distanceCm) {
        this.distanceCm = distanceCm;
    }

    public Boolean getObjectDetected() {
        return objectDetected;
    }

    public void setObjectDetected(Boolean objectDetected) {
        this.objectDetected = objectDetected;
    }

    public String getRawImagePath() {
        return rawImagePath;
    }

    public void setRawImagePath(String rawImagePath) {
        this.rawImagePath = rawImagePath;
    }

    public String getAnnotatedImagePath() {
        return annotatedImagePath;
    }

    public void setAnnotatedImagePath(String annotatedImagePath) {
        this.annotatedImagePath = annotatedImagePath;
    }

    public String getDetectedClass() {
        return detectedClass;
    }

    public void setDetectedClass(String detectedClass) {
        this.detectedClass = detectedClass;
    }

    public BigDecimal getConfidence() {
        return confidence;
    }

    public void setConfidence(BigDecimal confidence) {
        this.confidence = confidence;
    }

    public String getDecision() {
        return decision;
    }

    public void setDecision(String decision) {
        this.decision = decision;
    }

    public String getEventStatus() {
        return eventStatus;
    }

    public void setEventStatus(String eventStatus) {
        this.eventStatus = eventStatus;
    }

    public Integer getCountBefore() {
        return countBefore;
    }

    public void setCountBefore(Integer countBefore) {
        this.countBefore = countBefore;
    }

    public Integer getCountAfter() {
        return countAfter;
    }

    public void setCountAfter(Integer countAfter) {
        this.countAfter = countAfter;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}