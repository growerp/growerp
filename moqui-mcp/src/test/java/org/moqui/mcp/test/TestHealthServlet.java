/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 * 
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.mcp.test;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Test Health Servlet for MCP testing
 * Provides health check endpoints for test environment
 */
public class TestHealthServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try (PrintWriter writer = response.getWriter()) {
            if ("/mcp".equals(pathInfo)) {
                // Check MCP service health
                boolean mcpHealthy = checkMcpServiceHealth();
                writer.write("{\"status\":\"" + (mcpHealthy ? "healthy" : "unhealthy") + 
                          "\",\"service\":\"mcp\",\"timestamp\":\"" + System.currentTimeMillis() + "\"}");
            } else {
                // General health check
                writer.write("{\"status\":\"healthy\",\"service\":\"test\",\"timestamp\":\"" + 
                          System.currentTimeMillis() + "\"}");
            }
        }
    }
    
    /**
     * Check if MCP services are properly initialized
     */
    private boolean checkMcpServiceHealth() {
        try {
            // Check if MCP servlet is loaded and accessible
            // This is a basic check - in a real implementation you might
            // check specific MCP service endpoints or components
            return true; // For now, assume healthy if servlet loads
        } catch (Exception e) {
            return false;
        }
    }
}