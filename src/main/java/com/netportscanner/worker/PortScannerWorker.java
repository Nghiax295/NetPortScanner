package com.netportscanner.worker;


import com.netportscanner.bean.ScanJob;
import com.netportscanner.bean.ScanResult;
import com.netportscanner.bo.ScanBO;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.*;

public class PortScannerWorker implements Runnable {
    private static final int CONNECT_TIMEOUT = 2000;
    private static final int MAX_THREADS_PER_JOB = 20; 
    private static final int MAX_CONCURRENT_JOBS = 3;   
    private static final int POLL_INTERVAL = 2000;  
    
    private ScanBO scanBO;
    private volatile boolean running = true;
    private final ExecutorService jobExecutor;
    private final Set<Future<?>> runningJobs;
    
    public PortScannerWorker() {
        this.scanBO = new ScanBO();
        this.jobExecutor = Executors.newFixedThreadPool(MAX_CONCURRENT_JOBS);
        this.runningJobs = ConcurrentHashMap.newKeySet();
    }
    
    @Override
    public void run() {
        while (running) {
            try {
                cleanupCompletedJobs();
                int currentRunningJobs = runningJobs.size();
                if (currentRunningJobs < MAX_CONCURRENT_JOBS) {
                    int availableSlots = MAX_CONCURRENT_JOBS - currentRunningJobs;
                    List<ScanJob> queuedJobs = scanBO.getQueuedJobs();
                    if (!queuedJobs.isEmpty()) {
                        int jobsToProcess = Math.min(queuedJobs.size(), availableSlots);
                        for (int i = 0; i < jobsToProcess; i++) {
                            ScanJob job = queuedJobs.get(i);
                            processJobConcurrently(job);
                        }
                    }
                }
                
                Thread.sleep(POLL_INTERVAL);
                
            } catch (InterruptedException e) {
                running = false;
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                try {
                    Thread.sleep(5000);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    running = false;
                }
            }
        }
        
        shutdown();
    }
    
    private void processJobConcurrently(ScanJob job) {
        if (isJobAlreadyProcessing(job.getId())) {
            return;
        }
        
        Future<?> future = jobExecutor.submit(() -> {
            try {
                processSingleJob(job);
            } catch (Exception e) {
                scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.FAILED);
            }
        });
        runningJobs.add(future);
    }
    
    private void processSingleJob(ScanJob job) {
        if (!scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.SCANNING)) {
            return;
        }
        ExecutorService portExecutor = Executors.newFixedThreadPool(MAX_THREADS_PER_JOB);
        List<Future<?>> portFutures = new ArrayList<>();
        try {
            int totalPorts = job.getEndPort() - job.getStartPort() + 1;
            for (int port = job.getStartPort(); port <= job.getEndPort(); port++) {
                final int currentPort = port;
                Future<?> future = portExecutor.submit(() -> {
                    scanPort(job, currentPort);
                });
                portFutures.add(future);
            }
            for (Future<?> future : portFutures) {
                try {
                    future.get();
                } catch (Exception e) {}
            }
            scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.COMPLETED);            
        } catch (Exception e) {
            scanBO.updateJobStatus(job.getId(), ScanJob.ScanStatus.FAILED);
        } finally {
            portExecutor.shutdown();
            try {
                if (!portExecutor.awaitTermination(30, TimeUnit.SECONDS)) {
                    portExecutor.shutdownNow();
                }
            } catch (InterruptedException e) {
                portExecutor.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
    }
    
    private void scanPort(ScanJob job, int port) {
        ScanResult result = new ScanResult(job.getId(), port, ScanResult.PortStatus.CLOSED);
        long startTime = System.currentTimeMillis();
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(job.getTargetHost(), port), CONNECT_TIMEOUT);
            result.setStatus(ScanResult.PortStatus.OPEN);
            try {
                socket.setSoTimeout(1000);
                InputStream input = socket.getInputStream();
                OutputStream output = socket.getOutputStream();
                String banner = grabBanner(socket, port, job.getTargetHost());
                if (banner != null && !banner.trim().isEmpty()) {
                    result.setBanner(banner.substring(0, Math.min(banner.length(), 50)));
                }
            } catch (IOException e) {}
            
        } catch (IOException e) {
            if (e.getMessage().contains("Connection refused")) {
                result.setStatus(ScanResult.PortStatus.CLOSED);
            } else if (e.getMessage().contains("Connect timed out")) {
                result.setStatus(ScanResult.PortStatus.FILTERED);
            } else {
                result.setStatus(ScanResult.PortStatus.ERROR);
            }
        }
        long endTime = System.currentTimeMillis();
        result.setResponseTime((int) (endTime - startTime));
        scanBO.saveScanResult(result);
    }
    
    private String grabBanner(Socket socket, int port, String host) throws IOException {
        InputStream input = socket.getInputStream();
        OutputStream output = socket.getOutputStream();
        StringBuilder banner = new StringBuilder();
        try {
            byte[] payload = getSimplePayloadForPort(port);
            if (payload != null && payload.length > 0) {
                output.write(payload);
                output.flush();
            }
            byte[] buffer = new byte[1024];
            int bytesRead;
            Thread.sleep(200);
            while (input.available() > 0 && (bytesRead = input.read(buffer)) != -1) {
                banner.append(new String(buffer, 0, bytesRead));
                if (banner.length() > 500) break;
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (Exception e) {}
        return extractServiceName(banner.toString(), port);
    }

    private String extractServiceName(String banner, int port) {
        if (banner == null || banner.trim().isEmpty()) {
            return getServiceNameByPort(port);
        }
        String bannerLower = banner.toLowerCase();
        if (bannerLower.contains("ssh") || banner.contains("SSH-")) {
            return "SSH";
        } else if (bannerLower.contains("ftp")) {
            return "FTP";
        } else if (bannerLower.contains("smtp") || bannerLower.contains("esmtp")) {
            return "SMTP";
        } else if (bannerLower.contains("http") || bannerLower.contains("apache") || bannerLower.contains("nginx") || bannerLower.contains("iis")) {
            return "HTTP";
        } else if (bannerLower.contains("pop3")) {
            return "POP3";
        } else if (bannerLower.contains("imap")) {
            return "IMAP";
        } else if (bannerLower.contains("mysql")) {
            return "MySQL";
        } else if (bannerLower.contains("postgresql") || bannerLower.contains("postgres")) {
            return "PostgreSQL";
        } else if (bannerLower.contains("microsoft") || bannerLower.contains("rdp")) {
            return "RDP";
        } else if (bannerLower.contains("telnet")) {
            return "Telnet";
        } else {
            return getServiceNameByPort(port);
        }
    }

    private String getServiceNameByPort(int port) {
        switch (port) {
            case 21: return "FTP";
            case 22: return "SSH";
            case 23: return "Telnet";
            case 25: return "SMTP";
            case 53: return "DNS";
            case 67: return "DHCP";
            case 80: return "HTTP";
            case 110: return "POP3";
            case 135: return "RPC Endpoint Mappe";
            case 143: return "IMAP";
            case 443: return "HTTPS";
            case 445: return "Server Message Block";
            case 546: 
            case 547: return "DHCPv6";
            case 1443:
            case 1434: return "Microsoft SQL Server";
            case 554: return "RTSP";
            case 993: return "IMAPS";
            case 995: return "POP3S";
            case 3306: return "MySQL";
            case 3389: return "RDP";
            case 5432: return "PostgreSQL";
            case 27017: return "MongoDB";
            case 6379: return "Redis";
            case 11211: return "Memcached";
            default: 
                if (port <= 1024) {
                    return "Well-known Service";
                } else {
                    return "Custom Service";
                }
        }
    }
    
    private byte[] getSimplePayloadForPort(int port) {
        switch (port) {
            case 21: // FTP
            case 22: // SSH  
            case 23: // Telnet
            case 25: // SMTP
            case 110: // POP3
            case 143: // IMAP
            case 993: // IMAPS
            case 995: // POP3S
                return "\r\n".getBytes();
            case 80: // HTTP
            case 443: // HTTPS
            case 8080: // HTTP Alternate
                return "HEAD / HTTP/1.0\r\n\r\n".getBytes();
            default:
                return null;
        }
    }
    
    private void cleanupCompletedJobs() {
        runningJobs.removeIf(Future::isDone);
    }
    
    private boolean isJobAlreadyProcessing(Integer jobId) {
        ScanJob job = scanBO.getJobById(jobId);
        return job != null && job.getStatus() == ScanJob.ScanStatus.SCANNING;
    }
    
    private void shutdown() {
        running = false;
        for (Future<?> future : runningJobs) {
            future.cancel(true);
        }
        jobExecutor.shutdown();
        try {
            if (!jobExecutor.awaitTermination(30, TimeUnit.SECONDS)) {
                jobExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            jobExecutor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
    
    public void stop() {
        running = false;
    }
    
    public boolean isRunning() {
        return running;
    }
}