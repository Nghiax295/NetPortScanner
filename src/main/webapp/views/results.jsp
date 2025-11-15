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
    
    int openPorts = 0;
    if (results != null) {
        for (Object resultObj : results) {
            java.lang.reflect.Method getStatusMethod = resultObj.getClass().getMethod("getStatus");
            Object resultStatus = getStatusMethod.invoke(resultObj);
            if ("OPEN".equals(resultStatus.toString())) {
                openPorts++;
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

        <% if (results != null && !results.isEmpty()) { %>
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">Port Scan Results</h5>
                    <span class="badge bg-primary">
                        Open Ports: <%= openPorts %>
                    </span>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-striped table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Port</th>
                                    <th>Status</th>
                                    <th>Response Time</th>
                                    <th>Banner</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Object resultObj : results) { 
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
                                                <%= statusStr %>
                                            </span>
                                        </td>
                                        <td>
                                            <% if (responseTime != null) { %>
                                                <%= responseTime %> ms
                                            <% } else { %>
                                                -
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (banner != null && !banner.isEmpty()) { %>
                                                <code><%= banner %></code>
                                            <% } else { %>
                                                -
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
            <div class="alert alert-warning">
                No scan results available for this job.
            </div>
        <% } %>
    </div>
</body>
</html>