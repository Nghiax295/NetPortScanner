<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
%>
<!DOCTYPE html>
<html>
<head>
    <title>New Scan - NetPortScanner</title>
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
        <div class="row">
            <div class="col-md-3">
                <div class="list-group">
                    <a href="${pageContext.request.contextPath}/dashboard" class="list-group-item list-group-item-action">
                        <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                    </a>
                    <a href="${pageContext.request.contextPath}/scan" class="list-group-item list-group-item-action active">
                        <i class="fas fa-search me-2"></i>New Scan
                    </a>
                </div>
            </div>
            
            <div class="col-md-9">
                <div class="card">
                    <div class="card-header">
                        <h4 class="mb-0">Create New Port Scan</h4>
                    </div>
                    <div class="card-body">
                        <% if (error != null) { %>
                            <div class="alert alert-danger"><%= error %></div>
                        <% } %>
                        <% if (success != null) { %>
                            <div class="alert alert-success"><%= success %></div>
                        <% } %>

                        <form action="${pageContext.request.contextPath}/scan" method="post">
                            <div class="mb-3">
                                <label for="targetHost" class="form-label">Target Host</label>
                                <input type="text" class="form-control" id="targetHost" name="targetHost" 
                                       placeholder="example.com or 192.168.1.1" required>
                                <div class="form-text">Enter a domain name or IP address</div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="mb-3">
                                        <label for="startPort" class="form-label">Start Port</label>
                                        <input type="number" class="form-control" id="startPort" name="startPort" 
                                               min="1" max="65535" value="1" required>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="mb-3">
                                        <label for="endPort" class="form-label">End Port</label>
                                        <input type="number" class="form-control" id="endPort" name="endPort" 
                                               min="1" max="65535" value="100" required>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="alert alert-info">
                                <i class="fas fa-info-circle me-2"></i>
                                <strong>Note:</strong> Port range is limited to 1000 ports maximum for performance reasons.
                                Scanning may take some time depending on the range size.
                            </div>
                            
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-play me-1"></i>Start Scan
                            </button>
                            <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-secondary">Cancel</a>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>