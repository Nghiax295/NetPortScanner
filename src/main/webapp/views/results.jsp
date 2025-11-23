<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    Object jobObj = request.getAttribute("job");
    if (jobObj == null) {
        response.sendRedirect(request.getContextPath() + "/dashboard");
        return;
    }
    
    // Sử dụng reflection để truy cập methods
    java.lang.reflect.Method getId = jobObj.getClass().getMethod("getId");
    java.lang.reflect.Method getTargetHost = jobObj.getClass().getMethod("getTargetHost");
    java.lang.reflect.Method getStartPort = jobObj.getClass().getMethod("getStartPort");
    java.lang.reflect.Method getEndPort = jobObj.getClass().getMethod("getEndPort");
    java.lang.reflect.Method getStatus = jobObj.getClass().getMethod("getStatus");
    java.lang.reflect.Method getCreatedAt = jobObj.getClass().getMethod("getCreatedAt");
    java.lang.reflect.Method getStartedAt = jobObj.getClass().getMethod("getStartedAt");
    java.lang.reflect.Method getCompletedAt = jobObj.getClass().getMethod("getCompletedAt");
    java.lang.reflect.Method getResults = jobObj.getClass().getMethod("getResults");
    
    Integer jobId = (Integer) getId.invoke(jobObj);
    String targetHost = (String) getTargetHost.invoke(jobObj);
    Integer startPort = (Integer) getStartPort.invoke(jobObj);
    Integer endPort = (Integer) getEndPort.invoke(jobObj);
    Object status = getStatus.invoke(jobObj);
    Object createdAt = getCreatedAt.invoke(jobObj);
    Object startedAt = getStartedAt.invoke(jobObj);
    Object completedAt = getCompletedAt.invoke(jobObj);
    Object resultsObj = getResults.invoke(jobObj);
    
    java.util.List results = resultsObj != null ? (java.util.List) resultsObj : null;
    
    // Thêm biến lọc
    String filter = request.getParameter("filter");
    if (filter == null) filter = "all";
    
    int openPorts = 0;
    int closedPorts = 0;
    int filteredPorts = 0;
    int errorPorts = 0;
    
    java.util.List filteredResults = new java.util.ArrayList();
    
    if (results != null) {
        for (Object resultObj : results) {
            java.lang.reflect.Method getStatusMethod = resultObj.getClass().getMethod("getStatus");
            Object resultStatus = getStatusMethod.invoke(resultObj);
            String statusStr = resultStatus.toString();
            
            // Thống kê
            if ("OPEN".equals(statusStr)) openPorts++;
            else if ("CLOSED".equals(statusStr)) closedPorts++;
            else if ("FILTERED".equals(statusStr)) filteredPorts++;
            else if ("ERROR".equals(statusStr)) errorPorts++;
            
            // Lọc kết quả
            if ("all".equals(filter) || 
                ("open".equals(filter) && "OPEN".equals(statusStr)) ||
                ("closed".equals(filter) && "CLOSED".equals(statusStr)) ||
                ("filtered".equals(filter) && "FILTERED".equals(statusStr)) ||
                ("error".equals(filter) && "ERROR".equals(statusStr))) {
                filteredResults.add(resultObj);
            }
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Scan Results - NetPortScanner</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .filter-btn.active {
            font-weight: bold;
            box-shadow: 0 0 0 2px #0d6efd;
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
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2>Scan Results</h2>
            <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-secondary">
                <i class="fas fa-arrow-left me-1"></i>Back to Dashboard
            </a>
        </div>

        <div class="card mb-4">
            <div class="card-header">
                <h5 class="mb-0">Scan Information</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3">
                        <strong>Job ID:</strong> <%= jobId %>
                    </div>
                    <div class="col-md-3">
                        <strong>Target:</strong> <%= targetHost %>
                    </div>
                    <div class="col-md-3">
                        <strong>Port Range:</strong> <%= startPort %> - <%= endPort %>
                    </div>
                    <div class="col-md-3">
                        <strong>Status:</strong> 
                        <span class="badge bg-success"><%= status %></span>
                    </div>
                </div>
                <div class="row mt-2">
                    <div class="col-md-3">
                        <strong>Created:</strong> <%= createdAt %>
                    </div>
                    <div class="col-md-3">
                        <strong>Started:</strong> <%= startedAt != null ? startedAt : "N/A" %>
                    </div>
                    <div class="col-md-3">
                        <strong>Completed:</strong> <%= completedAt != null ? completedAt : "N/A" %>
                    </div>
                    <div class="col-md-3">
                        <strong>Total Ports:</strong> <%= endPort - startPort + 1 %>
                    </div>
                </div>
            </div>
        </div>

        <!-- Statistics Cards -->
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card text-white bg-success">
                    <div class="card-body text-center">
                        <h4><%= openPorts %></h4>
                        <p class="mb-0">Open Ports</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-secondary">
                    <div class="card-body text-center">
                        <h4><%= closedPorts %></h4>
                        <p class="mb-0">Closed Ports</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-warning">
                    <div class="card-body text-center">
                        <h4><%= filteredPorts %></h4>
                        <p class="mb-0">Filtered Ports</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-danger">
                    <div class="card-body text-center">
                        <h4><%= errorPorts %></h4>
                        <p class="mb-0">Error Ports</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Filter Buttons -->
        <div class="card mb-4">
            <div class="card-body">
                <div class="d-flex gap-2 flex-wrap">
                    <a href="?jobId=<%= jobId %>&filter=all" 
                       class="btn btn-outline-primary filter-btn <%= "all".equals(filter) ? "active" : "" %>">
                        <i class="fas fa-list me-1"></i>All Ports (<%= results != null ? results.size() : 0 %>)
                    </a>
                    <a href="?jobId=<%= jobId %>&filter=open" 
                       class="btn btn-outline-success filter-btn <%= "open".equals(filter) ? "active" : "" %>">
                        <i class="fas fa-check-circle me-1"></i>Open Ports (<%= openPorts %>)
                    </a>
                    <a href="?jobId=<%= jobId %>&filter=closed" 
                       class="btn btn-outline-secondary filter-btn <%= "closed".equals(filter) ? "active" : "" %>">
                        <i class="fas fa-times-circle me-1"></i>Closed Ports (<%= closedPorts %>)
                    </a>
                    <a href="?jobId=<%= jobId %>&filter=filtered" 
                       class="btn btn-outline-warning filter-btn <%= "filtered".equals(filter) ? "active" : "" %>">
                        <i class="fas fa-shield-alt me-1"></i>Filtered Ports (<%= filteredPorts %>)
                    </a>
                    <a href="?jobId=<%= jobId %>&filter=error" 
                       class="btn btn-outline-danger filter-btn <%= "error".equals(filter) ? "active" : "" %>">
                        <i class="fas fa-exclamation-triangle me-1"></i>Error Ports (<%= errorPorts %>)
                    </a>
                </div>
            </div>
        </div>

        <% if (filteredResults != null && !filteredResults.isEmpty()) { %>
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">
                        <i class="fas fa-filter me-2"></i>
                        <% 
                            String filterText = "All Ports";
                            if ("open".equals(filter)) filterText = "Open Ports";
                            else if ("closed".equals(filter)) filterText = "Closed Ports";
                            else if ("filtered".equals(filter)) filterText = "Filtered Ports";
                            else if ("error".equals(filter)) filterText = "Error Ports";
                        %>
                        <%= filterText %> (<%= filteredResults.size() %>)
                    </h5>
                    <div>
                        <span class="badge bg-primary me-2">
                            Showing <%= filteredResults.size() %> ports
                        </span>
                        <% if (!"all".equals(filter)) { %>
                            <a href="?jobId=<%= jobId %>&filter=all" class="btn btn-sm btn-outline-secondary">
                                <i class="fas fa-times me-1"></i>Clear Filter
                            </a>
                        <% } %>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th>Port</th>
                                    <th>Status</th>
                                    <th>Response Time</th>
                                    <th>Service</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Object resultObj : filteredResults) { 
                                    java.lang.reflect.Method getPort = resultObj.getClass().getMethod("getPort");
                                    java.lang.reflect.Method getResultStatus = resultObj.getClass().getMethod("getStatus");
                                    java.lang.reflect.Method getResponseTime = resultObj.getClass().getMethod("getResponseTime");
                                    java.lang.reflect.Method getBanner = resultObj.getClass().getMethod("getBanner");
                                    
                                    Integer port = (Integer) getPort.invoke(resultObj);
                                    Object resultStatus = getResultStatus.invoke(resultObj);
                                    Object responseTime = getResponseTime.invoke(resultObj);
                                    String banner = (String) getBanner.invoke(resultObj);
                                %>
                                    <tr>
                                        <td>
                                            <strong><%= port %></strong>
                                            <% if (port <= 1024) { %>
                                                <span class="badge bg-info ms-1">Well-known</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <%
                                                String badgeClass = "bg-secondary";
                                                String statusStr = resultStatus.toString();
                                                if ("OPEN".equals(statusStr)) {
                                                    badgeClass = "bg-success";
                                                } else if ("CLOSED".equals(statusStr)) {
                                                    badgeClass = "bg-secondary";
                                                } else if ("FILTERED".equals(statusStr)) {
                                                    badgeClass = "bg-warning";
                                                } else if ("ERROR".equals(statusStr)) {
                                                    badgeClass = "bg-danger";
                                                }
                                            %>
                                            <span class="badge <%= badgeClass %>">
                                                <i class="fas fa-<%= 
                                                    "OPEN".equals(statusStr) ? "check" : 
                                                    "CLOSED".equals(statusStr) ? "times" :
                                                    "FILTERED".equals(statusStr) ? "shield-alt" : "exclamation-triangle"
                                                %> me-1"></i>
                                                <%= statusStr %>
                                            </span>
                                        </td>
                                        <td>
                                            <% if (responseTime != null) { %>
                                                <i class="fas fa-clock me-1 text-muted"></i>
                                                <%= responseTime %> ms
                                            <% } else { %>
                                                <span class="text-muted">-</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (banner != null && !banner.isEmpty()) { %>
                                                <code class="bg-light p-1 rounded"><%= banner %></code>
                                            <% } else { %>
                                                <span class="text-muted">Unknown</span>
                                            <% } %>
                                        </td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        <% } else { %>
            <div class="alert alert-info text-center">
                <i class="fas fa-info-circle me-2"></i>
                <% if (results == null || results.isEmpty()) { %>
                    No scan results available for this job.
                <% } else { %>
                    No ports match the current filter "<%= filter %>".
                    <a href="?jobId=<%= jobId %>&filter=all" class="alert-link">Show all ports</a>
                <% } %>
            </div>
        <% } %>
    </div>

    <script>
        // Highlight active filter button
        document.addEventListener('DOMContentLoaded', function() {
            const filterButtons = document.querySelectorAll('.filter-btn');
            filterButtons.forEach(btn => {
                if (btn.classList.contains('active')) {
                    btn.classList.remove('btn-outline-primary', 'btn-outline-success', 'btn-outline-secondary', 'btn-outline-warning', 'btn-outline-danger');
                    if (btn.href.includes('filter=open')) btn.classList.add('btn-success');
                    else if (btn.href.includes('filter=closed')) btn.classList.add('btn-secondary');
                    else if (btn.href.includes('filter=filtered')) btn.classList.add('btn-warning');
                    else if (btn.href.includes('filter=error')) btn.classList.add('btn-danger');
                    else btn.classList.add('btn-primary');
                }
            });
        });
    </script>
</body>
</html>