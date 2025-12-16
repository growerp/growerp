package growerp.mcp

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import org.moqui.context.ExecutionContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

/**
 * MCP (Model Context Protocol) Client for communicating with browsermcp server
 * 
 * This client allows Moqui services to interact with the browsermcp MCP server
 * for browser automation tasks.
 */
class MCPClient {
    protected final static Logger logger = LoggerFactory.getLogger(MCPClient.class)
    
    private String mcpServerUrl
    private HttpClient httpClient
    private JsonSlurper jsonSlurper
    
    /**
     * Initialize MCP client
     * @param serverUrl URL of browsermcp server (e.g., "http://localhost:3000")
     */
    MCPClient(String serverUrl = "http://localhost:3000") {
        this.mcpServerUrl = serverUrl
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(30))
            .build()
        this.jsonSlurper = new JsonSlurper()
    }
    
    /**
     * Call an MCP tool on the browsermcp server
     * 
     * @param toolName Name of the MCP tool (e.g., "browser_navigate", "browser_click")
     * @param params Map of parameters for the tool
     * @return Map containing the tool result
     */
    Map callTool(String toolName, Map params = [:]) {
        try {
            logger.info("Calling MCP tool: ${toolName} with params: ${params}")
            
            def requestBody = [
                jsonrpc: "2.0",
                id: System.currentTimeMillis(),
                method: "tools/call",
                params: [
                    name: toolName,
                    arguments: params
                ]
            ]
            
            def request = HttpRequest.newBuilder()
                .uri(URI.create("${mcpServerUrl}/mcp"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(JsonOutput.toJson(requestBody)))
                .timeout(Duration.ofMinutes(2))
                .build()
            
            def response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            
            if (response.statusCode() != 200) {
                throw new Exception("MCP server returned status ${response.statusCode()}: ${response.body()}")
            }
            
            def result = jsonSlurper.parseText(response.body()) as Map
            
            if (result.error) {
                logger.error("MCP tool error: ${result.error}")
                throw new Exception("MCP tool error: ${result.error.message}")
            }
            
            logger.info("MCP tool result: ${result.result}")
            return result.result as Map
            
        } catch (Exception e) {
            logger.error("Error calling MCP tool ${toolName}: ${e.message}", e)
            throw e
        }
    }
    
    /**
     * Navigate browser to a URL
     */
    Map navigate(String url) {
        return callTool("mcp_browsermcp_browser_navigate", [url: url])
    }
    
    /**
     * Click an element on the page
     */
    Map click(String ref, String element = "button") {
        return callTool("mcp_browsermcp_browser_click", [ref: ref, element: element])
    }
    
    /**
     * Type text into an input field
     */
    Map type(String ref, String text, String element = "input", boolean submit = false) {
        return callTool("mcp_browsermcp_browser_type", [
            ref: ref,
            text: text,
            element: element,
            submit: submit
        ])
    }
    
    /**
     * Take a screenshot of the current page
     */
    Map screenshot() {
        return callTool("mcp_browsermcp_browser_screenshot", [:])
    }
    
    /**
     * Get accessibility snapshot of the page (for finding elements)
     */
    Map snapshot() {
        return callTool("mcp_browsermcp_browser_snapshot", [:])
    }
    
    /**
     * Wait for specified time in seconds
     */
    Map wait(double seconds) {
        return callTool("mcp_browsermcp_browser_wait", [time: seconds])
    }
    
    /**
     * Go back in browser history
     */
    Map goBack() {
        return callTool("mcp_browsermcp_browser_go_back", [:])
    }
    
    /**
     * Go forward in browser history
     */
    Map goForward() {
        return callTool("mcp_browsermcp_browser_go_forward", [:])
    }
}
