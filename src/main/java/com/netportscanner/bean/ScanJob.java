package com.netportscanner.bean;

import java.time.LocalDateTime;
import java.util.List;

public class ScanJob {
    private Integer id;
    private Integer userId;
    private String targetHost;
    private Integer startPort;
    private Integer endPort;
    private ScanStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private List<ScanResult> results;
    
    public enum ScanStatus {
        QUEUED, SCANNING, COMPLETED, FAILED
    }
    
    // Constructors
    public ScanJob() {}
    
    public ScanJob(Integer userId, String targetHost, Integer startPort, Integer endPort) {
        this.userId = userId;
        this.targetHost = targetHost;
        this.startPort = startPort;
        this.endPort = endPort;
        this.status = ScanStatus.QUEUED;
    }
    
    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    
    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }
    
    public String getTargetHost() { return targetHost; }
    public void setTargetHost(String targetHost) { this.targetHost = targetHost; }
    
    public Integer getStartPort() { return startPort; }
    public void setStartPort(Integer startPort) { this.startPort = startPort; }
    
    public Integer getEndPort() { return endPort; }
    public void setEndPort(Integer endPort) { this.endPort = endPort; }
    
    public ScanStatus getStatus() { return status; }
    public void setStatus(ScanStatus status) { this.status = status; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public LocalDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(LocalDateTime startedAt) { this.startedAt = startedAt; }
    
    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
    
    public List<ScanResult> getResults() { return results; }
    public void setResults(List<ScanResult> results) { this.results = results; }
}
