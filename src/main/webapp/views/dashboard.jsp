<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    Object userObj = session.getAttribute("user");
    Object jobsObj = request.getAttribute("jobs");
    
    if (userObj == null) {
        response.sendRedirect(request.getContextPath() + "/auth/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard - NetPortScanner</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .status-badge {
            transition: all 0.3s ease;
        }
        .pulse {
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
        }
        .auto-refresh-indicator {
            position: fixed;
            top: 10px;
            right: 10px;
            z-index: 1000;
            background: rgba(13, 110, 253, 0.1);
            border-radius: 5px;
            padding: 5px 10px;
        }
        .refreshing {
            background: rgba(25, 135, 84, 0.1);
        }
    </style>
</head>
<body>


    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="#">NetPortScanner</a>
            <div class="navbar-nav ms-auto">
                <span class="navbar-text me-3">Welcome, ${user.username}</span>
                <a class="nav-link" href="${pageContext.request.contextPath}/auth/logout">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="row">
            <div class="col-md-3">
                <div class="list-group">
                    <a href="${pageContext.request.contextPath}/dashboard" class="list-group-item list-group-item-action active">
                        <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                    </a>
                    <a href="${pageContext.request.contextPath}/scan" class="list-group-item list-group-item-action">
                        <i class="fas fa-search me-2"></i>New Scan
                    </a>
                </div>
            </div>
            
            <div class="col-md-9">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h2>Scan Jobs</h2>
                    <a href="${pageContext.request.contextPath}/scan" class="btn btn-primary">
                        <i class="fas fa-plus me-1"></i>New Scan
                    </a>
                </div>

                <div id="jobsContainer">
                    <!-- Jobs content will be dynamically updated here -->
                    <% if (jobsObj == null) { %>
                        <div class="alert alert-info">
                            No scan jobs found. <a href="${pageContext.request.contextPath}/scan">Create your first scan job</a>.
                        </div>
                    <% } else { 
                        java.util.List jobs = (java.util.List) jobsObj;
                        if (jobs.isEmpty()) { %>
                            <div class="alert alert-info">
                                No scan jobs found. <a href="${pageContext.request.contextPath}/scan">Create your first scan job</a>.
                            </div>
                        <% } else { %>
                            <div class="table-responsive">
                                <table class="table table-striped">
                                    <thead>
                                        <tr>
                                            <th>ID</th>
                                            <th>Target</th>
                                            <th>Port Range</th>
                                            <th>Status</th>
                                            <th>Created</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody id="jobsTableBody">
                                        <% for (Object jobObj : jobs) { 
                                            Object job = jobObj;
                                            java.lang.reflect.Method getId = job.getClass().getMethod("getId");
                                            java.lang.reflect.Method getTargetHost = job.getClass().getMethod("getTargetHost");
                                            java.lang.reflect.Method getStartPort = job.getClass().getMethod("getStartPort");
                                            java.lang.reflect.Method getEndPort = job.getClass().getMethod("getEndPort");
                                            java.lang.reflect.Method getStatus = job.getClass().getMethod("getStatus");
                                            java.lang.reflect.Method getCreatedAt = job.getClass().getMethod("getCreatedAt");
                                            
                                            Integer id = (Integer) getId.invoke(job);
                                            String targetHost = (String) getTargetHost.invoke(job);
                                            Integer startPort = (Integer) getStartPort.invoke(job);
                                            Integer endPort = (Integer) getEndPort.invoke(job);
                                            Object status = getStatus.invoke(job);
                                            Object createdAt = getCreatedAt.invoke(job);
                                        %>
                                            <tr data-job-id="<%= id %>">
                                                <td><%= id %></td>
                                                <td><%= targetHost %></td>
                                                <td><%= startPort %> - <%= endPort %></td>
                                                <td>
                                                    <%
                                                        String badgeClass = "bg-secondary";
                                                        String statusStr = status.toString();
                                                        if ("QUEUED".equals(statusStr)) {
                                                            badgeClass = "bg-warning";
                                                        } else if ("SCANNING".equals(statusStr)) {
                                                            badgeClass = "bg-info pulse";
                                                        } else if ("COMPLETED".equals(statusStr)) {
                                                            badgeClass = "bg-success";
                                                        } else if ("FAILED".equals(statusStr)) {
                                                            badgeClass = "bg-danger";
                                                        }
                                                    %>
                                                    <span class="badge status-badge <%= badgeClass %>" id="status-<%= id %>">
                                                        <%= statusStr %>
                                                    </span>
                                                </td>
                                                <td><%= createdAt %></td>
                                                <td>
                                                    <% if ("COMPLETED".equals(statusStr)) { %>
                                                        <a href="${pageContext.request.contextPath}/scan/results?jobId=<%= id %>" 
                                                           class="btn btn-sm btn-outline-primary">
                                                            <i class="fas fa-eye me-1"></i>View Results
                                                        </a>
                                                    <% } else if ("SCANNING".equals(statusStr)) { %>
                                                        <span class="text-muted">Scanning in progress...</span>
                                                    <% } %>
                                                </td>
                                            </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        <% } %>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <script>
        let refreshInterval;
        const REFRESH_INTERVAL = 3000; // 3 seconds

        // Initialize auto-refresh
        function initializeAutoRefresh() {
            startAutoRefresh();
        }

        function startAutoRefresh() {
            stopAutoRefresh(); // Clear existing interval
            refreshInterval = setInterval(refreshJobs, REFRESH_INTERVAL);
        }

        function stopAutoRefresh() {
            if (refreshInterval) {
                clearInterval(refreshInterval);
                refreshInterval = null;
            }
        }

        function refreshJobs() {
            // Show refreshing state
            const indicator = document.getElementById('refreshIndicator');
            indicator.classList.add('refreshing');
            
            fetch('${pageContext.request.contextPath}/dashboard?ajax=true', {
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.text();
            })
            .then(html => {
                updateLastUpdateTime();
                
                // Parse the HTML response and extract the jobs table
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                const newTableBody = doc.querySelector('#jobsTableBody');
                
                if (newTableBody) {
                    updateJobsTable(newTableBody.innerHTML);
                }
                
                // Remove refreshing state
                indicator.classList.remove('refreshing');
            })
            .catch(error => {
                console.error('Error refreshing jobs:', error);
                document.getElementById('refreshStatus').textContent = 'Refresh failed';
                indicator.classList.remove('refreshing');
            });
        }

        function updateJobsTable(newContent) {
            const tableBody = document.getElementById('jobsTableBody');
            if (!tableBody) return;

            // Store current scroll position
            const scrollPosition = window.scrollY;

            // Update the table content
            tableBody.innerHTML = newContent;

            // Add visual feedback for updated rows
            highlightUpdatedRows();

            // Enhance status badges
            enhanceStatusBadges();

            // Restore scroll position
            window.scrollTo(0, scrollPosition);
        }

        function highlightUpdatedRows() {
            const rows = document.querySelectorAll('#jobsTableBody tr');
            rows.forEach(row => {
                row.style.transition = 'all 0.3s ease';
                row.style.backgroundColor = '#f8fffe';
                
                setTimeout(() => {
                    row.style.backgroundColor = '';
                }, 1000);
            });
        }

        function updateLastUpdateTime() {
            const now = new Date();
            const timeString = now.toLocaleTimeString();
        }

        // Enhanced status badge animations
        function enhanceStatusBadges() {
            const badges = document.querySelectorAll('.status-badge');
            badges.forEach(badge => {
                const status = badge.textContent.trim();
                
                if (status === 'SCANNING') {
                    if (!badge.classList.contains('pulse')) {
                        badge.classList.add('pulse');
                    }
                } else {
                    badge.classList.remove('pulse');
                }
                
                // Add smooth transitions for status changes
                badge.style.transition = 'all 0.5s ease';
            });
        }

        // Initialize when page loads
        document.addEventListener('DOMContentLoaded', function() {
            initializeAutoRefresh();
            enhanceStatusBadges();
            updateLastUpdateTime();
            
            // Handle page visibility changes
            document.addEventListener('visibilitychange', function() {
                if (document.hidden) {
                    stopAutoRefresh();
                } else {
                    startAutoRefresh();
                }
            });
        });

        // Cleanup on page unload
        window.addEventListener('beforeunload', function() {
            stopAutoRefresh();
        });
    </script>
</body>
</html>