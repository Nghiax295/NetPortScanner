package com.netportscanner.worker;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@WebListener
public class WorkerManager implements ServletContextListener {
    private ExecutorService executorService;
    private PortScannerWorker worker;
    
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        // Start the background worker
        worker = new PortScannerWorker();
        executorService = Executors.newSingleThreadExecutor();
        executorService.execute(worker);
        
        sce.getServletContext().log("PortScannerWorker started");
    }
    
    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // Stop the background worker
        if (worker != null) {
            worker.stop();
        }
        if (executorService != null) {
            executorService.shutdown();
        }
        
        sce.getServletContext().log("PortScannerWorker stopped");
    }
}