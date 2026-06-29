/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.mcp

import groovy.transform.CompileStatic
import org.moqui.context.*
import org.moqui.context.MessageFacade.MessageInfo
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import jakarta.servlet.ServletContext
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import jakarta.servlet.http.HttpSession
import java.util.ArrayList
import java.util.EventListener

/** Stub implementation of WebFacade for testing/screen rendering without a real HTTP request */
@CompileStatic
class WebFacadeStub implements WebFacade {
    protected final static Logger logger = LoggerFactory.getLogger(WebFacadeStub.class)

    protected final ExecutionContextFactory ecfi
    protected final Map<String, Object> parameters
    protected final Map<String, Object> sessionAttributes
    protected final String requestMethod
    protected final String screenPath
    
    protected HttpServletRequest httpServletRequest
    protected HttpServletResponse httpServletResponse
    protected HttpSession httpSession
    
    protected Map<String, Object> requestAttributes = [:]
    protected Map<String, Object> applicationAttributes = [:]
    protected Map<String, Object> errorParameters = [:]
    
    protected List<MessageInfo> savedMessages = []
    protected List<MessageInfo> savedPublicMessages = []
    protected List<String> savedErrors = []
    protected List<ValidationError> savedValidationErrors = []
    
    protected List<Map> screenHistory = []
    
    // Web context objects needed by screens
    protected Set<String> html_scripts = new LinkedHashSet<>()
    protected Set<String> html_stylesheets = new LinkedHashSet<>()
    
    protected String responseText = null
    protected Object responseJsonObj = null
    boolean skipJsonSerialize = false
    
    WebFacadeStub(ExecutionContextFactory ecfi, Map<String, Object> parameters,
                   Map<String, Object> sessionAttributes, String requestMethod, String screenPath = null) {
        this.ecfi = ecfi
        this.parameters = parameters ?: [:]
        this.sessionAttributes = sessionAttributes ?: [:]
        this.requestMethod = requestMethod ?: "GET"
        this.screenPath = screenPath
        
        // Create mock HTTP objects
        createMockHttpObjects()
    }
    
    protected void createMockHttpObjects() {
        // Create mock HttpSession first
        this.httpSession = new MockHttpSession(this.sessionAttributes)
        
        // Create mock HttpServletRequest with session and screen path
        this.httpServletRequest = new MockHttpServletRequest(this.parameters, this.requestMethod, this.httpSession, this.screenPath)
        
        // Create mock HttpServletResponse with String output capture
        this.httpServletResponse = new MockHttpServletResponse()
        
        // Note: Objects are linked through the mock implementations
    }
    
    @Override
    String getRequestUrl() {
        if (logger.isDebugEnabled()) {
            logger.debug("WebFacadeStub.getRequestUrl() called - screenPath: ${screenPath}")
        }
        // Build URL based on actual screen path
        def path = screenPath ? "/${screenPath}" : "/"
        def url = "http://localhost:8080${path}"
        if (logger.isDebugEnabled()) {
            logger.debug("WebFacadeStub.getRequestUrl() returning: ${url}")
        }
        return url
    }
    
    @Override
    Map<String, Object> getParameters() {
        Map<String, Object> combined = [:]
        combined.putAll(parameters)
        combined.putAll(getRequestParameters())
        combined.putAll(getSessionAttributes())
        combined.putAll(getRequestAttributes())
        combined.putAll(getApplicationAttributes())
        return combined
    }
    
    @Override
    HttpServletRequest getRequest() { return httpServletRequest }
    
    @Override
    Map<String, Object> getRequestAttributes() { return requestAttributes }
    
    @Override
    Map<String, Object> getRequestParameters() { return parameters }
    
    @Override
    Map<String, Object> getSecureRequestParameters() { return parameters }
    
    @Override
    String getHostName(boolean withPort) {
        return withPort ? "localhost:8080" : "localhost"
    }
    
    String getWebappName() {
        // Return a default webappName since this is a stub implementation
        // In real Moqui, this would come from the webapp configuration
        return "mcp"
    }
    
    @Override
    String getPathInfo() { 
        if (logger.isDebugEnabled()) {
            logger.debug("WebFacadeStub.getPathInfo() called - screenPath: ${screenPath}")
        }
        // For standalone screens, return empty path to render the screen itself
        // For screens with subscreen paths, return the relative path
        def pathInfo = screenPath ? "/${screenPath}" : ""
        if (logger.isDebugEnabled()) {
            logger.debug("WebFacadeStub.getPathInfo() returning: ${pathInfo}")
        }
        return pathInfo
    }
    
    @Override
    ArrayList<String> getPathInfoList() {
        if (logger.isDebugEnabled()) {
            logger.debug("WebFacadeStub.getPathInfoList() called - screenPath: ${screenPath}")
        }
        // IMPORTANT: Don't delegate to WebFacadeImpl - it expects real HTTP servlet context
        // Return mock path info for MCP screen rendering based on actual screen path
        def pathInfo = getPathInfo()
        def pathList = new ArrayList<String>()
        if (pathInfo && pathInfo.startsWith("/")) {
            // Split path and filter out empty parts
            def pathParts = pathInfo.substring(1).split("/") as List
            pathList = new ArrayList<String>(pathParts.findAll { it && it.toString().length() > 0 })
        }
        if (logger.isDebugEnabled()) {
            logger.debug("WebFacadeStub.getPathInfoList() returning: ${pathList} (from pathInfo: ${pathInfo})")
        }
        return pathList
    }
    
    @Override
    String getRequestBodyText() { return null }
    
    @Override
    String getResourceDistinctValue() { return "test" }
    
    @Override
    HttpServletResponse getResponse() { return httpServletResponse }
    
    @Override
    HttpSession getSession() { return httpSession }
    
    @Override
    Map<String, Object> getSessionAttributes() { return sessionAttributes }
    
    @Override
    String getSessionToken() { return "test-token" }

    String getSessionId() { return httpSession?.getId() }
    
    @Override
    ServletContext getServletContext() { 
        return new MockServletContext() 
    }
    
    @Override
    Map<String, Object> getApplicationAttributes() { return applicationAttributes }
    
    @Override
    String getWebappRootUrl(boolean requireFullUrl, Boolean useEncryption) {
        return requireFullUrl ? "http://localhost:8080" : ""
    }
    
    @Override
    Map<String, Object> getErrorParameters() { return errorParameters }
    
    @Override
    List<MessageInfo> getSavedMessages() { return savedMessages }
    
    @Override
    List<MessageInfo> getSavedPublicMessages() { return savedPublicMessages }
    
    @Override
    List<String> getSavedErrors() { return savedErrors }
    
    @Override
    List<ValidationError> getSavedValidationErrors() { return savedValidationErrors }
    
    @Override
    List<ValidationError> getFieldValidationErrors(String fieldName) {
        return savedValidationErrors.findAll { it.field == fieldName }
    }
    
    @Override
    List<Map> getScreenHistory() { return screenHistory }
    
    List<String> getHtmlScripts() { return new ArrayList<>(html_scripts) }
    
    List<String> getHtmlStyleSheets() { return new ArrayList<>(html_stylesheets) }
    
    @Override
    void sendJsonResponse(Object responseObj) {
        if (!skipJsonSerialize) {
            this.responseJsonObj = responseObj
            try {
                def mapper = new com.fasterxml.jackson.databind.ObjectMapper()
                this.responseText = mapper.writeValueAsString(responseObj)
            } catch (Exception e) {
                logger.warn("Error serializing JSON: ${e.message}")
                this.responseText = responseObj.toString()
            }
        } else {
            this.responseJsonObj = responseObj
            this.responseText = responseObj.toString()
        }
    }
    
    @Override
    void sendJsonError(int statusCode, String message, Throwable origThrowable) {
        this.responseText = "Error ${statusCode}: ${message}"
    }
    
    @Override
    void sendTextResponse(String text) {
        this.responseText = text
    }
    
    @Override
    void sendTextResponse(String text, String contentType, String filename) {
        this.responseText = text
    }
    
    @Override
    void sendResourceResponse(String location) {
        this.responseText = "Resource: ${location}"
    }
    
    @Override
    void sendResourceResponse(String location, boolean inline) {
        this.responseText = "Resource: ${location} (inline: ${inline})"
    }
    
    @Override
    void sendError(int errorCode, String message, Throwable origThrowable) {
        this.responseText = "Error ${errorCode}: ${message}"
    }
    
    @Override
    void handleJsonRpcServiceCall() {
        this.responseText = "JSON-RPC not implemented in stub"
    }
    
    @Override
    void handleEntityRestCall(List<String> extraPathNameList, boolean masterNameInPath) {
        this.responseText = "Entity REST not implemented in stub"
    }
    
    @Override
    void handleServiceRestCall(List<String> extraPathNameList) {
        this.responseText = "Service REST not implemented in stub"
    }
    
    @Override
    void handleSystemMessage(List<String> extraPathNameList) {
        this.responseText = "System message not implemented in stub"
    }
    
    // Save methods - capture errors/messages before redirect so they're available after render
    void saveMessagesToSession() {
        // Capture current errors and validation errors from ExecutionContext
        if (ecfi instanceof org.moqui.impl.context.ExecutionContextFactoryImpl) {
            org.moqui.impl.context.ExecutionContextFactoryImpl ecfiImpl = (org.moqui.impl.context.ExecutionContextFactoryImpl) ecfi
            org.moqui.context.ExecutionContext eci = ecfiImpl.getEci()
            if (eci != null) {
                MessageFacade mf = eci.getMessage()
                if (mf != null) {
                    List<String> errors = mf.getErrors()
                    if (errors != null && errors.size() > 0) {
                        savedErrors.addAll(errors)
                        logger.info("WebFacadeStub.saveMessagesToSession: Captured ${errors.size()} errors: ${errors}")
                    }
                    List<ValidationError> valErrors = mf.getValidationErrors()
                    if (valErrors != null && valErrors.size() > 0) {
                        savedValidationErrors.addAll(valErrors)
                        logger.info("WebFacadeStub.saveMessagesToSession: Captured ${valErrors.size()} validation errors")
                    }
                }
            }
        }
    }
    
    void saveRequestParametersToSession() {
        // Store parameters for potential re-display
        sessionAttributes.put("moqui.saved.parameters", new HashMap(parameters))
    }
    
    void saveErrorParametersToSession() {
        // Store error parameters 
        errorParameters.putAll(parameters)
    }
    
    void saveParametersToSession(Map parameters) {
        if (parameters) {
            sessionAttributes.put("moqui.saved.parameters", new HashMap(parameters))
        }
    }
    
    // Helper methods for ScreenTestImpl
    String getResponseText() { 
        if (responseText != null) {
            logger.info("getResponseText: returning responseText (length: ${responseText.length()})")
            return responseText
        }
        if (httpServletResponse instanceof MockHttpServletResponse) {
            // Flush the writer to ensure all content is captured
            try {
                httpServletResponse.getWriter().flush()
            } catch (IOException e) {
                logger.warn("Error flushing response writer: ${e.message}")
            }
            def content = ((MockHttpServletResponse) httpServletResponse).getResponseContent()
            logger.info("getResponseText: returning content from mock response (length: ${content?.length() ?: 0})")
            return content
        }
        logger.warn("getResponseText: httpServletResponse is not MockHttpServletResponse: ${httpServletResponse?.getClass()?.getName()}")
        return null
    }
    Object getResponseJsonObj() { return responseJsonObj }
    
    // Mock HTTP classes
    static class MockHttpServletRequest implements HttpServletRequest {
        private final Map<String, Object> parameters
        private final String method
        private HttpSession session
        private String screenPath
        private String remoteUser = null
        private java.security.Principal userPrincipal = null
        private Map<String, Object> attributes = [:]
        
        MockHttpServletRequest(Map<String, Object> parameters, String method, HttpSession session = null, String screenPath = null) {
            this.parameters = parameters ?: [:]
            this.method = method ?: "GET"
            this.session = session
            this.screenPath = screenPath
            
            // Mark request as authenticated for MCP - bypasses CSRF token check for transitions
            // This is safe because MCP requests are already authenticated via the MCP session
            this.attributes["moqui.request.authenticated"] = "true"
            
            // Extract user information from session attributes for authentication
            if (session) {
                def username = session.getAttribute("username")
                def userId = session.getAttribute("userId")
                if (username) {
                    this.remoteUser = username as String
                    this.userPrincipal = new java.security.Principal() {
                        String getName() { return username as String }
                    }
                }
            }
        }
        
        @Override String getRequestId() { return null }
        @Override String getProtocolRequestId() { return null }
        @Override jakarta.servlet.ServletConnection getServletConnection() { return null }
        @Override String getMethod() { return method }
        @Override String getScheme() { return "http" }
        @Override String getServerName() { return "localhost" }
        @Override int getServerPort() { return 8080 }
        @Override String getRequestURI() { 
            // Build URI based on actual screen path
            def path = screenPath ? "/${screenPath}" : "/"
            return path
        }
        @Override String getContextPath() { return "" }
        @Override String getServletPath() { return "" }
        @Override String getQueryString() { return null }
        @Override String getParameter(String name) { return parameters.get(name) as String }
        @Override Map<String, String[]> getParameterMap() { 
            return parameters.collectEntries { k, v -> [k, [v?.toString()] as String[]] }
        }
        @Override String[] getParameterValues(String name) { 
            def value = parameters.get(name)
            return value ? [value.toString()] as String[] : null
        }
        @Override HttpSession getSession() { return session }
        @Override HttpSession getSession(boolean create) { return session }
        @Override String getHeader(String name) { return null }
        @Override java.util.Enumeration<String> getHeaderNames() { return Collections.enumeration([]) }
        @Override java.util.Enumeration<String> getHeaders(String name) { return Collections.enumeration([]) }
        @Override String getRemoteAddr() { return "127.0.0.1" }
        @Override String getRemoteHost() { return "localhost" }
        @Override boolean isSecure() { return false }
        @Override String getCharacterEncoding() { return "UTF-8" }
        @Override void setCharacterEncoding(String env) throws java.io.UnsupportedEncodingException {}
        @Override int getContentLength() { return 0 }
        @Override String getContentType() { return null }
        @Override java.io.BufferedReader getReader() throws java.io.IOException { 
            return new BufferedReader(new StringReader("")) 
        }
        @Override String getProtocol() { return "HTTP/1.1" }
        
        // Other required methods with minimal implementations
        @Override Object getAttribute(String name) { return attributes.get(name) }
        @Override void setAttribute(String name, Object value) { attributes[name] = value }
        @Override void removeAttribute(String name) { attributes.remove(name) }
        @Override java.util.Enumeration<String> getAttributeNames() { return Collections.enumeration([]) }
        @Override String getAuthType() { return null }
        @Override String getRemoteUser() { return remoteUser }
        @Override boolean isUserInRole(String role) { return false }
        @Override java.security.Principal getUserPrincipal() { return userPrincipal }
        @Override String getRequestedSessionId() { return null }
        @Override StringBuffer getRequestURL() { 
            // Build URL based on actual screen path
            def path = screenPath ? "/${screenPath}" : "/"
            return new StringBuffer("http://localhost:8080${path}")
        }
        @Override String getPathInfo() { 
            // Return path info based on actual screen path
            return screenPath ? "/${screenPath}" : "/"
        }
        @Override String getPathTranslated() { return null }
        @Override boolean isRequestedSessionIdValid() { return false }
        @Override boolean isRequestedSessionIdFromCookie() { return false }
        @Override boolean isRequestedSessionIdFromURL() { return false }
        @Override java.util.Locale getLocale() { return Locale.US }
        @Override java.util.Enumeration<java.util.Locale> getLocales() { return Collections.enumeration([Locale.US]) }
        @Override jakarta.servlet.ServletInputStream getInputStream() throws java.io.IOException { 
            return new jakarta.servlet.ServletInputStream() {
                @Override boolean isReady() { return true }
                @Override void setReadListener(jakarta.servlet.ReadListener readListener) {}
                @Override int read() throws java.io.IOException { return -1 }
                @Override boolean isFinished() { return true }
            }
        }
        @Override String getLocalAddr() { return "127.0.0.1" }
        @Override String getLocalName() { return "localhost" }
        @Override int getLocalPort() { return 8080 }
        @Override ServletContext getServletContext() { return null }
        @Override boolean isAsyncStarted() { return false }
        @Override boolean isAsyncSupported() { return false }
        @Override jakarta.servlet.AsyncContext getAsyncContext() { return null }
        @Override jakarta.servlet.DispatcherType getDispatcherType() { return null }
        
        // Additional required methods for HttpServletRequest
        @Override long getContentLengthLong() { return 0 }
        @Override java.util.Enumeration<String> getParameterNames() { return Collections.enumeration(parameters.keySet()) }
        @Override jakarta.servlet.RequestDispatcher getRequestDispatcher(String path) { return null }
        @Override int getRemotePort() { return 0 }
        @Override jakarta.servlet.AsyncContext startAsync() { return null }
        @Override jakarta.servlet.AsyncContext startAsync(jakarta.servlet.ServletRequest request, jakarta.servlet.ServletResponse response) { return null }
        @Override jakarta.servlet.http.Cookie[] getCookies() { return null }
        @Override long getDateHeader(String name) { return 0 }
        @Override int getIntHeader(String name) { return 0 }
        @Override String changeSessionId() { return session ? session.getId() : "mock-session-id" }
        @Override boolean authenticate(jakarta.servlet.http.HttpServletResponse response) { return false }
        @Override void login(String username, String password) {}
        @Override void logout() {}
        @Override java.util.Collection<jakarta.servlet.http.Part> getParts() { return [] }
        @Override jakarta.servlet.http.Part getPart(String name) { return null }
        @Override <T extends jakarta.servlet.http.HttpUpgradeHandler> T upgrade(Class<T> handlerClass) { return null }
    }
    
    static class MockHttpServletResponse implements HttpServletResponse {
        private StringWriter writer = new StringWriter()
        private PrintWriter printWriter = new PrintWriter(writer)
        private HttpSession mockSession
        private int status = 200
        private String contentType = "text/html"
        private String characterEncoding = "UTF-8"
        private Map<String, String> headers = [:]
        
        void setMockSession(HttpSession session) { this.mockSession = session }
        
        @Override PrintWriter getWriter() throws java.io.IOException { return printWriter }
        @Override jakarta.servlet.ServletOutputStream getOutputStream() throws java.io.IOException {
            return new jakarta.servlet.ServletOutputStream() {
                @Override boolean isReady() { return true }
                @Override void setWriteListener(jakarta.servlet.WriteListener writeListener) {}
                @Override void write(int b) throws java.io.IOException { writer.write(b) }
            }
        }
        
        @Override void setStatus(int sc) { this.status = sc }
        @Override int getStatus() { return status }
        @Override void setContentType(String type) { this.contentType = type }
        @Override String getContentType() { return contentType }
        @Override void setCharacterEncoding(String charset) { this.characterEncoding = charset }
        @Override String getCharacterEncoding() { return characterEncoding }
        @Override void setHeader(String name, String value) { headers[name] = value }
        @Override void addHeader(String name, String value) { headers[name] = value }
        @Override String getHeader(String name) { return headers[name] }
        @Override java.util.Collection<String> getHeaders(String name) { 
            return headers[name] ? [headers[name]] : [] 
        }
        @Override java.util.Collection<String> getHeaderNames() { return headers.keySet() }
        @Override void setContentLength(int len) {}
        @Override void setContentLengthLong(long len) {}
        @Override void setBufferSize(int size) {}
        @Override int getBufferSize() { return 0 }
        @Override void flushBuffer() throws java.io.IOException { printWriter.flush() }
        @Override void resetBuffer() {}
        @Override boolean isCommitted() { return false }
        @Override void reset() {}
        @Override Locale getLocale() { return Locale.US }
        
        String getResponseContent() { return writer.toString() }
        
        // Other required methods with minimal implementations
        @Override String encodeURL(String url) { return url }
        @Override String encodeRedirectURL(String url) { return url }
        @Override void sendError(int sc, String msg) throws java.io.IOException { status = sc }
        @Override void sendError(int sc) throws java.io.IOException { status = sc }
        @Override void sendRedirect(String location) throws java.io.IOException {}
        @Override void sendRedirect(String location, int sc, boolean clearBuffer) throws java.io.IOException {}
        @Override void setDateHeader(String name, long date) {}
        @Override void addDateHeader(String name, long date) {}
        @Override void setIntHeader(String name, int value) {}
        @Override void addIntHeader(String name, int value) {}
        @Override boolean containsHeader(String name) { return headers.containsKey(name) }
        
        // Additional required methods for HttpServletResponse
        @Override void setLocale(Locale locale) {}
        @Override void addCookie(jakarta.servlet.http.Cookie cookie) {}
    }
    
    static class MockHttpSession implements HttpSession {
        private final Map<String, Object> attributes
        private long creationTime = System.currentTimeMillis()
        private String id = "mock-session-" + System.currentTimeMillis()
        
        MockHttpSession(Map<String, Object> attributes) {
            this.attributes = attributes ?: [:]
        }
        
        @Override Object getAttribute(String name) { return attributes.get(name) }
        @Override void setAttribute(String name, Object value) { attributes[name] = value }
        @Override void removeAttribute(String name) { attributes.remove(name) }
        @Override java.util.Enumeration<String> getAttributeNames() { return Collections.enumeration(attributes.keySet()) }
        @Override long getCreationTime() { return creationTime }
        @Override String getId() { return id }
        @Override long getLastAccessedTime() { return System.currentTimeMillis() }
        @Override jakarta.servlet.ServletContext getServletContext() { return null }
        @Override void setMaxInactiveInterval(int interval) {}
        @Override int getMaxInactiveInterval() { return 1800 }
        @Override void invalidate() {}
        @Override boolean isNew() { return false }
    }
    
    static class MockServletContext implements ServletContext {
        private final Map<String, Object> attributes = [:]
        
        @Override Object getAttribute(String name) { return attributes.get(name) }
        @Override void setAttribute(String name, Object value) { attributes[name] = value }
        @Override void removeAttribute(String name) { attributes.remove(name) }
        @Override java.util.Enumeration<String> getAttributeNames() { return Collections.enumeration(attributes.keySet()) }
        @Override String getServletContextName() { return "MockServletContext" }
        @Override String getServerInfo() { return "Mock Server" }
        @Override int getMajorVersion() { return 4 }
        @Override int getMinorVersion() { return 0 }
        @Override String getMimeType(String file) { return null }
        @Override String getRealPath(String path) { return null }
        @Override java.io.InputStream getResourceAsStream(String path) { return null }
        @Override java.net.URL getResource(String path) throws java.net.MalformedURLException { return null }
        @Override jakarta.servlet.RequestDispatcher getRequestDispatcher(String path) { return null }
        @Override jakarta.servlet.RequestDispatcher getNamedDispatcher(String name) { return null }
        @Override String getInitParameter(String name) { return null }
        @Override java.util.Enumeration<String> getInitParameterNames() { return Collections.enumeration([]) }
        @Override boolean setInitParameter(String name, String value) { return false }
        @Override String getContextPath() { return "" }
        @Override ServletContext getContext(String uripath) { return null }
        @Override int getEffectiveMajorVersion() { return 4 }
        @Override int getEffectiveMinorVersion() { return 0 }
        @Override void log(String msg) {}
        @Override void log(String msg, Throwable throwable) {}
        
        // Additional required methods for ServletContext
        @Override java.util.Set<String> getResourcePaths(String path) { return null }
        @Override jakarta.servlet.ServletRegistration.Dynamic addServlet(String servletName, String className) { return null }
        @Override jakarta.servlet.ServletRegistration.Dynamic addServlet(String servletName, jakarta.servlet.Servlet servlet) { return null }
        @Override jakarta.servlet.ServletRegistration.Dynamic addServlet(String servletName, Class<? extends jakarta.servlet.Servlet> servletClass) { return null }
        @Override jakarta.servlet.ServletRegistration.Dynamic addJspFile(String jspName, String jspFile) { return null }
        @Override <T extends jakarta.servlet.Servlet> T createServlet(Class<T> clazz) { return null }
        @Override jakarta.servlet.ServletRegistration getServletRegistration(String servletName) { return null }
        @Override java.util.Map<String, ? extends jakarta.servlet.ServletRegistration> getServletRegistrations() { return [:] }
        @Override jakarta.servlet.FilterRegistration.Dynamic addFilter(String filterName, String className) { return null }
        @Override jakarta.servlet.FilterRegistration.Dynamic addFilter(String filterName, jakarta.servlet.Filter filter) { return null }
        @Override jakarta.servlet.FilterRegistration.Dynamic addFilter(String filterName, Class<? extends jakarta.servlet.Filter> filterClass) { return null }
        @Override <T extends jakarta.servlet.Filter> T createFilter(Class<T> clazz) { return null }
        @Override jakarta.servlet.FilterRegistration getFilterRegistration(String filterName) { return null }
        @Override java.util.Map<String, ? extends jakarta.servlet.FilterRegistration> getFilterRegistrations() { return [:] }
        @Override jakarta.servlet.SessionCookieConfig getSessionCookieConfig() { return null }
        @Override void setSessionTrackingModes(java.util.Set<jakarta.servlet.SessionTrackingMode> sessionTrackingModes) {}
        @Override java.util.Set<jakarta.servlet.SessionTrackingMode> getDefaultSessionTrackingModes() { return [] as Set }
        @Override java.util.Set<jakarta.servlet.SessionTrackingMode> getEffectiveSessionTrackingModes() { return [] as Set }
        @Override void addListener(String className) {}
        @Override void addListener(EventListener listener) {}
        @Override void addListener(Class<? extends EventListener> listenerClass) {}
        @Override <T extends EventListener> T createListener(Class<T> clazz) { return null }
        @Override jakarta.servlet.descriptor.JspConfigDescriptor getJspConfigDescriptor() { return null }
        @Override ClassLoader getClassLoader() { return null }
        @Override void declareRoles(String... roleNames) {}
        @Override String getVirtualServerName() { return "localhost" }
        @Override int getSessionTimeout() { return 30 }
        @Override void setSessionTimeout(int sessionTimeout) {}
        @Override String getRequestCharacterEncoding() { return "UTF-8" }
        @Override void setRequestCharacterEncoding(String encoding) {}
        @Override String getResponseCharacterEncoding() { return "UTF-8" }
        @Override void setResponseCharacterEncoding(String encoding) {}
    }
}
