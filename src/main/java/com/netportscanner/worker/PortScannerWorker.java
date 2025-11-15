package com.netportscanner.worker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.netportscanner.bean.ScanJob;
import com.netportscanner.bean.ScanResult;
import com.netportscanner.bo.ScanBO;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public class PortScannerWorker implements Runnable {
    private static final Logger logger = LoggerFactory.getLogger(PortScannerWorker.class);
    private static final int TIMEOUT = 3000; // 3 seconds
    private static final int MAX_THREADS = 50;
    
    private ScanBO scanBO;
    private volatile boolean running = true;
    
    public PortScannerWorker() {
        this.scanBO = new ScanBO();
    }
    
    @Override
    public void run() {
        logger.info("PortScannerWorker started");
        
        while (running) {
            try {
                // Get queued jobs
                List<ScanJob> queuedJobs = scanBO.getQueuedJobs();
                
                for (ScanJob job : queuedJobs) {
                    processJob(job);
                }
                
                // Sleep before checking for new jobs again
                Thread.sleep(5000); // 5 seconds
                
            } catch (InterruptedException e) {
                logger.info("PortScannerWorker interrupted");
                running = false;
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                logger.error("Error in PortScannerWorker", e);
                try {
                    Thread.sleep(10000); // Sleep longer on error
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    running = false;
                }
            }
        }
        
        logger.info("PortScannerWorker stopped");
    }
    
    private void processJob(ScanJob job) {
        logger.info("Processing job {} for target {}", job.getId(), job.getTargetHost());
        
        // Update job status to SCANNING
        if (!scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.SCANNING)) {
            logger.error("Failed to update job status to SCANNING for job {}", job.getId());
            return;
        }
        
        ExecutorService executor = Executors.newFixedThreadPool(MAX_THREADS);
        List<Future<?>> futures = new ArrayList<>();
        
        try {
            // Scan each port in the range
            for (int port = job.getStartPort(); port <= job.getEndPort(); port++) {
                final int currentPort = port;
                Future<?> future = executor.submit(() -> {
                    scanPort(job, currentPort);
                });
                futures.add(future);
            }
            
            // Wait for all scans to complete
            for (Future<?> future : futures) {
                try {
                    future.get();
                } catch (Exception e) {
                    logger.error("Error in port scan task", e);
                }
            }
            
            // Update job status to COMPLETED
            scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.COMPLETED);
            logger.info("Completed job {} for target {}", job.getId(), job.getTargetHost());
            
        } catch (Exception e) {
            logger.error("Error processing job {}", job.getId(), e);
            scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.FAILED);
        } finally {
            executor.shutdown();
            try {
                if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                    executor.shutdownNow();
                }
            } catch (InterruptedException e) {
                executor.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
    }
    
    private void scanPort(ScanJob job, int port) {
        ScanResult result = new ScanResult(job.getId(), port, ScanResult.PortStatus.CLOSED);
        
        long startTime = System.currentTimeMillis();
        
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(job.getTargetHost(), port), TIMEOUT);
            result.setStatus(ScanResult.PortStatus.OPEN);
            
            // Try to read banner (with shorter timeout)
            try {
                socket.setSoTimeout(1000);
                // Banner grabbing logic can be added here
            } catch (IOException e) {
                // Ignore banner read errors
            }
            
        } catch (IOException e) {
            if (e.getMessage().contains("Connection refused")) {
                result.setStatus(ScanResult.PortStatus.CLOSED);
            } else if (e.getMessage().contains("connect timed out")) {
                result.setStatus(ScanResult.PortStatus.FILTERED);
            } else {
                result.setStatus(ScanResult.PortStatus.ERROR);
            }
        }
        
        long endTime = System.currentTimeMillis();
        result.setResponseTime((int) (endTime - startTime));
        
        // Save result
        scanBO.saveScanResult(result);
    }
    
    public void stop() {
        running = false;
    }
}