package org.moqui.impl.webapp;

import javax.servlet.*;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletResponseWrapper;
import java.io.IOException;

/**
 * Servlet filter to set correct MIME types for Flutter web assets
 */
public class MimeTypeFilter implements Filter {
    
    @Override
    public void init(FilterConfig config) throws ServletException {
    }
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        String path = ((javax.servlet.http.HttpServletRequest) request).getRequestURI();
        
        // Only process specific file types
        if (path != null) {
            HttpServletResponseWrapper wrappedResponse = new HttpServletResponseWrapper((HttpServletResponse) response) {
                private boolean contentTypeSet = false;
                
                @Override
                public void setContentType(String type) {
                    if (type == null) {
                        super.setContentType(type);
                        return;
                    }
                    
                    // Fix MIME types for Flutter web assets
                    if (path.endsWith(".mjs")) {
                        super.setContentType("application/javascript; charset=UTF-8");
                        contentTypeSet = true;
                    } else if (path.endsWith(".wasm")) {
                        super.setContentType("application/wasm");
                        contentTypeSet = true;
                    } else if (path.endsWith(".js")) {
                        super.setContentType("application/javascript; charset=UTF-8");
                        contentTypeSet = true;
                    } else {
                        super.setContentType(type);
                    }
                }
                
                @Override
                public void setHeader(String name, String value) {
                    // Intercept and fix Content-Type header
                    if ("Content-Type".equalsIgnoreCase(name) && value != null) {
                        if (path.endsWith(".mjs")) {
                            super.setHeader(name, "application/javascript; charset=UTF-8");
                        } else if (path.endsWith(".wasm")) {
                            super.setHeader(name, "application/wasm");
                        } else if (path.endsWith(".js")) {
                            super.setHeader(name, "application/javascript; charset=UTF-8");
                        } else {
                            super.setHeader(name, value);
                        }
                    } else {
                        super.setHeader(name, value);
                    }
                }
                
                @Override
                public void addHeader(String name, String value) {
                    // Intercept and fix Content-Type header
                    if ("Content-Type".equalsIgnoreCase(name) && value != null) {
                        if (path.endsWith(".mjs")) {
                            super.setHeader(name, "application/javascript; charset=UTF-8");
                        } else if (path.endsWith(".wasm")) {
                            super.setHeader(name, "application/wasm");
                        } else if (path.endsWith(".js")) {
                            super.setHeader(name, "application/javascript; charset=UTF-8");
                        } else {
                            super.addHeader(name, value);
                        }
                    } else {
                        super.addHeader(name, value);
                    }
                }
                
                @Override
                public void setCharacterEncoding(String charset) {
                    // Don't add charset for WASM files - they're binary
                    if (!path.endsWith(".wasm")) {
                        super.setCharacterEncoding(charset);
                    }
                }
            };
            
            chain.doFilter(request, wrappedResponse);
        } else {
            chain.doFilter(request, response);
        }
    }
    
    @Override
    public void destroy() {
    }
}
