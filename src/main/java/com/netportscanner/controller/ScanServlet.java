package com.netportscanner.controller;


import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.netportscanner.bean.User;
import com.netportscanner.bo.ScanBO;

import java.io.IOException;

@SuppressWarnings("serial")
@WebServlet("/scan/*")
public class ScanServlet extends HttpServlet {
    private ScanBO scanBO;
    
    @Override
    public void init() throws ServletException {
        this.scanBO = new ScanBO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }
        
        String action = request.getPathInfo();
        
        if (action != null && action.equals("/results")) {
            String jobIdParam = request.getParameter("jobId");
            if (jobIdParam != null) {
                try {
                    Integer jobId = Integer.parseInt(jobIdParam);
                    User user = (User) session.getAttribute("user");
                    
                    var job = scanBO.getJobWithResults(jobId);
                    if (job != null && job.getUserId().equals(user.getId())) {
                        request.setAttribute("job", job);
                        request.getRequestDispatcher("/views/results.jsp").forward(request, response);
                        return;
                    }
                } catch (NumberFormatException e) {
                    // Invalid job ID
                }
            }
            response.sendRedirect(request.getContextPath() + "/dashboard");
        } else {
            request.getRequestDispatcher("/views/scan.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        String targetHost = request.getParameter("targetHost");
        String startPortParam = request.getParameter("startPort");
        String endPortParam = request.getParameter("endPort");
        
        try {
            Integer startPort = Integer.parseInt(startPortParam);
            Integer endPort = Integer.parseInt(endPortParam);
            
            // Validate port range
            if (startPort < 1 || endPort > 65535 || startPort > endPort) {
                request.setAttribute("error", "Invalid port range. Ports must be between 1 and 65535, and start port must be less than or equal to end port.");
                request.getRequestDispatcher("/views/scan.jsp").forward(request, response);
                return;
            }
            
            // Validate that range is not too large (performance consideration)
            if ((endPort - startPort) > 1000) {
                request.setAttribute("error", "Port range too large. Maximum 1000 ports per scan.");
                request.getRequestDispatcher("/views/scan.jsp").forward(request, response);
                return;
            }
            
            Integer jobId = scanBO.createScanJob(user.getId(), targetHost, startPort, endPort);
            
            if (jobId != null) {
                request.setAttribute("success", "Scan job created successfully! Job ID: " + jobId);
            } else {
                request.setAttribute("error", "Failed to create scan job. Please check your inputs.");
            }
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid port numbers. Please enter valid integers.");
        } catch (Exception e) {
            request.setAttribute("error", "Error creating scan job: " + e.getMessage());
        }
        
        request.getRequestDispatcher("/views/scan.jsp").forward(request, response);
    }
}