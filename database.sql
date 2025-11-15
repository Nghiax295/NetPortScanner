-- Tạo database
CREATE DATABASE netportscanner;
USE netportscanner;

-- Bảng users
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Bảng scan_jobs
CREATE TABLE scan_jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    target_host VARCHAR(255) NOT NULL,
    start_port INT NOT NULL,
    end_port INT NOT NULL,
    status ENUM('QUEUED', 'SCANNING', 'COMPLETED', 'FAILED') DEFAULT 'QUEUED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng scan_results
CREATE TABLE scan_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    port INT NOT NULL,
    status ENUM('OPEN', 'CLOSED', 'FILTERED', 'ERROR') NOT NULL,
    response_time INT NULL,
    banner VARCHAR(500) NULL,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES scan_jobs(id) ON DELETE CASCADE,
    UNIQUE KEY unique_job_port (job_id, port)
);

-- Indexes for performance
CREATE INDEX idx_scan_jobs_status ON scan_jobs(status);
CREATE INDEX idx_scan_jobs_user_id ON scan_jobs(user_id);
CREATE INDEX idx_scan_results_job_id ON scan_results(job_id);