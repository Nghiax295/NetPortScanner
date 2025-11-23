package com.netportscanner.dao;


import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import com.netportscanner.bean.ScanJob;
import com.netportscanner.bean.ScanResult;
import com.netportscanner.until.DBConnection;

public class ScanJobDAO {
    
    public Integer createScanJob(ScanJob job) {
        String sql = "INSERT INTO scan_jobs (user_id, target_host, start_port, end_port, status) VALUES (?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setInt(1, job.getUserId());
            stmt.setString(2, job.getTargetHost());
            stmt.setInt(3, job.getStartPort());
            stmt.setInt(4, job.getEndPort());
            stmt.setString(5, job.getStatus().name());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows > 0) {
                try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        return generatedKeys.getInt(1);
                    }
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        
        return null;
    }
    
    public List<ScanJob> getJobsByUserId(Integer userId) {
        List<ScanJob> jobs = new ArrayList<>();
        String sql = "SELECT * FROM scan_jobs WHERE user_id = ? ORDER BY created_at DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                jobs.add(mapResultSetToScanJob(rs));
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        
        return jobs;
    }
    
    public Optional<ScanJob> getJobById(Integer jobId) {
        String sql = "SELECT * FROM scan_jobs WHERE id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, jobId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToScanJob(rs));
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        
        return Optional.empty();
    }
    
    public List<ScanJob> getQueuedJobs() {
        List<ScanJob> jobs = new ArrayList<>();
        String sql = "SELECT * FROM scan_jobs WHERE status = 'QUEUED' ORDER BY created_at ASC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                jobs.add(mapResultSetToScanJob(rs));
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        
        return jobs;
    }
    
    public boolean updateJobStatus(Integer jobId, ScanJob.ScanStatus status) {
        String sql = "UPDATE scan_jobs SET status = ?, started_at = CASE WHEN status = 'QUEUED' AND ? = 'SCANNING' THEN NOW() ELSE started_at END, completed_at = CASE WHEN ? = 'COMPLETED' OR ? = 'FAILED' THEN NOW() ELSE completed_at END WHERE id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, status.name());
            stmt.setString(2, status.name());
            stmt.setString(3, status.name());
            stmt.setString(4, status.name());
            stmt.setInt(5, jobId);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        
        return false;
    }
    
    public void saveScanResult(ScanResult result) {
        String sql = "INSERT INTO scan_results (job_id, port, status, response_time, banner) VALUES (?, ?, ?, ?, ?) " +
                    "ON DUPLICATE KEY UPDATE status = VALUES(status), response_time = VALUES(response_time), banner = VALUES(banner)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, result.getJobId());
            stmt.setInt(2, result.getPort());
            stmt.setString(3, result.getStatus().name());
            
            if (result.getResponseTime() != null) {
                stmt.setInt(4, result.getResponseTime());
            } else {
                stmt.setNull(4, Types.INTEGER);
            }
            
            stmt.setString(5, result.getBanner());
            
            stmt.executeUpdate();
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
    
    public List<ScanResult> getResultsByJobId(Integer jobId) {
        List<ScanResult> results = new ArrayList<>();
        String sql = "SELECT * FROM scan_results WHERE job_id = ? ORDER BY port ASC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, jobId);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                results.add(mapResultSetToScanResult(rs));
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        
        return results;
    }
    
    private ScanJob mapResultSetToScanJob(ResultSet rs) throws SQLException {
        ScanJob job = new ScanJob();
        job.setId(rs.getInt("id"));
        job.setUserId(rs.getInt("user_id"));
        job.setTargetHost(rs.getString("target_host"));
        job.setStartPort(rs.getInt("start_port"));
        job.setEndPort(rs.getInt("end_port"));
        job.setStatus(ScanJob.ScanStatus.valueOf(rs.getString("status")));
        job.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
        
        Timestamp startedAt = rs.getTimestamp("started_at");
        if (startedAt != null) {
            job.setStartedAt(startedAt.toLocalDateTime());
        }
        
        Timestamp completedAt = rs.getTimestamp("completed_at");
        if (completedAt != null) {
            job.setCompletedAt(completedAt.toLocalDateTime());
        }
        
        return job;
    }
    
    private ScanResult mapResultSetToScanResult(ResultSet rs) throws SQLException {
        ScanResult result = new ScanResult();
        result.setId(rs.getInt("id"));
        result.setJobId(rs.getInt("job_id"));
        result.setPort(rs.getInt("port"));
        result.setStatus(ScanResult.PortStatus.valueOf(rs.getString("status")));
        result.setResponseTime(rs.getInt("response_time"));
        if (rs.wasNull()) {
            result.setResponseTime(null);
        }
        result.setBanner(rs.getString("banner"));
        result.setScannedAt(rs.getTimestamp("scanned_at").toLocalDateTime());
        return result;
    }
    
}
