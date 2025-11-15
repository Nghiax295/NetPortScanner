package com.netportscanner.bo;

import java.util.List;

import com.netportscanner.bean.ScanJob;
import com.netportscanner.bean.ScanResult;
import com.netportscanner.dao.ScanJobDAO;

public class ScanBO {
private ScanJobDAO scanJobDAO;
    
    public ScanBO() {
        this.scanJobDAO = new ScanJobDAO();
    }
    
    public Integer createScanJob(Integer userId, String targetHost, Integer startPort, Integer endPort) {
        // Validate input
        if (targetHost == null || targetHost.trim().isEmpty() || 
            startPort == null || endPort == null || 
            startPort < 1 || endPort > 65535 || startPort > endPort) {
            return null;
        }
        
        ScanJob job = new ScanJob(userId, targetHost.trim(), startPort, endPort);
        return scanJobDAO.createScanJob(job);
    }
    
    public List<ScanJob> getUserJobs(Integer userId) {
        return scanJobDAO.getJobsByUserId(userId);
    }
    
    public ScanJob getJobWithResults(Integer jobId) {
        return scanJobDAO.getJobById(jobId)
                .map(job -> {
                    List<ScanResult> results = scanJobDAO.getResultsByJobId(jobId);
                    job.setResults(results);
                    return job;
                })
                .orElse(null);
    }
    
    public List<ScanJob> getQueuedJobs() {
        return scanJobDAO.getQueuedJobs();
    }
    
    public boolean updateJobStatus(Integer jobId, ScanJob.ScanStatus status) {
        return scanJobDAO.updateJobStatus(jobId, status);
    }
    
    public void saveScanResult(ScanResult result) {
        scanJobDAO.saveScanResult(result);
    }
}
