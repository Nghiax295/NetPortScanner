package com.netportscanner.controller;


import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.netportscanner.bean.ScanJob;
import com.netportscanner.bean.User;
import com.netportscanner.bo.ScanBO;

import java.io.IOException;
import java.util.List;

@SuppressWarnings("serial")
@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {
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
        
        User user = (User) session.getAttribute("user");
        List<ScanJob> jobs = scanBO.getUserJobs(user.getId());
        
        request.setAttribute("jobs", jobs);
        request.getRequestDispatcher("/views/dashboard.jsp").forward(request, response);
    }
}