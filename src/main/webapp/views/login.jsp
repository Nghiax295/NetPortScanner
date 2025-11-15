<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Login - NetPortScanner</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .auth-container { max-width: 400px; margin: 100px auto; }
    </style>
</head>
<body>
    <div class="container">
        <div class="auth-container">
            <h2 class="text-center mb-4">NetPortScanner</h2>
            <div class="card">
                <div class="card-body">
                    <h4 class="card-title text-center">Login</h4>
                    
                    <% if (error != null) { %>
                        <div class="alert alert-danger"><%= error %></div>
                    <% } %>
                    <% if (success != null) { %>
                        <div class="alert alert-success"><%= success %></div>
                    <% } %>
                    
                    <form action="${pageContext.request.contextPath}/auth/login" method="post">
                        <div class="mb-3">
                            <label for="username" class="form-label">Username</label>
                            <input type="text" class="form-control" id="username" name="username" required>
                        </div>
                        <div class="mb-3">
                            <label for="password" class="form-label">Password</label>
                            <input type="password" class="form-control" id="password" name="password" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100">Login</button>
                    </form>
                    
                    <div class="text-center mt-3">
                        <a href="${pageContext.request.contextPath}/auth/register">Don't have an account? Register</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>