package com.netportscanner.bean;

import java.time.LocalDateTime;

public class ScanResult {
    private Integer id;
    private Integer jobId;
    private Integer port;
    private PortStatus status;
    private Integer responseTime;
    private String banner;
    private LocalDateTime scannedAt;
    
    public enum PortStatus {
        OPEN, CLOSED, FILTERED, ERROR
    }
    
    // Constructors
    public ScanResult() {}
    
    public ScanResult(Integer jobId, Integer port, PortStatus status) {
        this.jobId = jobId;
        this.port = port;
        this.status = status;
    }
    
    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    
    public Integer getJobId() { return jobId; }
    public void setJobId(Integer jobId) { this.jobId = jobId; }
    
    public Integer getPort() { return port; }
    public void setPort(Integer port) { this.port = port; }
    
    public PortStatus getStatus() { return status; }
    public void setStatus(PortStatus status) { this.status = status; }
    
    public Integer getResponseTime() { return responseTime; }
    public void setResponseTime(Integer responseTime) { this.responseTime = responseTime; }
    
    public String getBanner() { return banner; }
    public void setBanner(String banner) { this.banner = banner; }
    
    public LocalDateTime getScannedAt() { return scannedAt; }
    public void setScannedAt(LocalDateTime scannedAt) { this.scannedAt = scannedAt; }
}