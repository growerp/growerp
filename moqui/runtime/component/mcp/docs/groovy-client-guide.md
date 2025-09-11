# GrowERP MCP Client Examples (Groovy)

This directory contains Groovy-based examples for integrating with the GrowERP MCP (Model Context Protocol) server. These examples are specifically designed to work with the existing GrowERP/Moqui technology stack.

## 📁 Files Overview

### Core Client Files
- **`test_mcp_client.groovy`** - Basic MCP client with testing and validation
- **`advanced_mcp_examples.groovy`** - Advanced patterns using Groovy DSL
- **`quick_setup.sh`** - Automated setup and testing script
- **`deploy_mcp_server.sh`** - MCP server deployment automation

### Documentation
- **`DEPLOYMENT_GUIDE.md`** - Comprehensive deployment and integration guide
- **`README.md`** - This overview file

## 🚀 Quick Start

### 1. Setup and Test
```bash
# One-command setup and test
./quick_setup.sh

# Or manual approach
./deploy_mcp_server.sh    # Start MCP server
groovy test_mcp_client.groovy  # Test basic functionality
```

### 2. Basic Usage
```groovy
// Simple MCP client
GrowERPMCPClient client = new GrowERPMCPClient()
client.initialize()

// Call tools
def result = client.callTool("get_companies", [limit: 5])
println result
```

### 3. Advanced Patterns
```groovy
// Use Groovy DSL for complex operations
AdvancedMCPClient client = new AdvancedMCPClient()

def businessData = client.tools {
    ping()
    companies(limit: 10)
    users(limit: 5)
    custom("get_reports", [type: "sales"])
}
```

## 🎯 Key Features

### Groovy-Native Integration
- **@Grab annotations** for automatic dependency management
- **Groovy DSL** for intuitive MCP operations  
- **Traits and builders** for reusable components
- **CompletableFuture** support for async operations

### Business Intelligence
- **System health monitoring** via MCP tools
- **Business data extraction** (companies, users, reports)
- **AI prompt generation** with business context
- **Real-time data integration** for AI applications

### AI Integration Patterns
- **Prompt builders** for structured AI queries
- **Context injection** with live business data
- **Response processing** and business logic
- **Multi-platform AI support** (OpenAI, Claude, custom)

## 🏗️ Architecture Patterns

### 1. DSL Builder Pattern
```groovy
// Fluent interface for MCP operations
client.tools {
    ping()
    companies(limit: 5)
    custom("analytics", [period: "month"])
}
```

### 2. Trait-Based Integration
```groovy
// Reusable MCP capabilities
class MyAIService implements MCPEnabled {
    def processBusinessQuery(String query) {
        withBusinessContext { data ->
            return createContextualPrompt(query)
        }
    }
}
```

### 3. AI Assistant Framework
```groovy
// Complete AI assistant with business context
BusinessAIAssistant assistant = new BusinessAIAssistant()
def response = assistant.processQuery("Analyze my business performance")
```

## 🔧 Customization

### Adding Custom Tools
```groovy
// Extend the ToolBuilder for custom operations
class CustomToolBuilder extends ToolBuilder {
    def salesReports(Map args = [:]) {
        results.salesReports = client.makeRequest("tools/call", [
            name: "get_sales_reports",
            arguments: args
        ])
    }
}
```

### Custom AI Integrations
```groovy
// Integrate with your preferred AI service
class OpenAIIntegration {
    def processWithContext(String query) {
        def mcpData = getMCPBusinessContext()
        def prompt = createAIPrompt(query, mcpData)
        return callOpenAI(prompt)
    }
}
```

## 🔒 Production Considerations

### Security
- Add authentication to MCP requests
- Use HTTPS for production deployments
- Implement rate limiting and access controls

### Performance
- Use async operations for multiple MCP calls
- Implement caching for frequently accessed data
- Monitor MCP server performance and scaling

### Monitoring
- Log all MCP interactions for debugging
- Monitor AI integration performance
- Set up alerts for MCP server health

## 🧪 Testing

### Unit Tests
```bash
# Run basic connectivity tests
groovy test_mcp_client.groovy

# Run advanced pattern tests
groovy advanced_mcp_examples.groovy
```

### Integration Tests
```groovy
// Available in the main test suite
// See: src/test/groovy/McpServer*Spec.groovy
```

## 📖 Examples

### Example 1: Business Health Check
```groovy
def client = new GrowERPMCPClient()
client.initialize()

def health = client.callTool("ping_system")
if (!health.result.isError) {
    println "✓ System is healthy: ${health.result.content[0].text}"
}
```

### Example 2: AI Business Analysis
```groovy
def assistant = new BusinessAIAssistant()
def analysis = assistant.processQuery("What trends do you see in our data?")

println "AI Insights: ${analysis.aiResponse}"
println "Based on: ${analysis.context.keySet()}"
```

### Example 3: Custom Workflow
```groovy
def client = new AdvancedMCPClient()

// Async data gathering
def futures = [
    client.makeRequestAsync("tools/call", [name: "get_companies"]),
    client.makeRequestAsync("tools/call", [name: "get_users"]),
    client.makeRequestAsync("tools/call", [name: "get_reports"])
]

def results = futures.collect { it.get() }
println "Gathered ${results.size()} data sets in parallel"
```

## 🔗 Related Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment instructions
- **[GrowERP Documentation](https://www.growerp.com)** - Full system documentation
- **[MCP Specification](https://modelcontextprotocol.io)** - Protocol details
- **[Groovy Documentation](https://groovy-lang.org)** - Language reference

## 🐛 Troubleshooting

### Common Issues

**"Cannot connect to MCP server"**
```bash
# Check if server is running
curl http://localhost:8081
# If not running, start it
./deploy_mcp_server.sh
```

**"@Grab dependencies fail"**
```bash
# Check internet connectivity
curl http://repo1.maven.org/maven2/
# Or use local Maven repository
groovy -Dgrape.root=/path/to/local/repo test_mcp_client.groovy
```

**"Tool execution failed"**
```groovy
// Check tool availability
def tools = client.listTools()
println "Available tools: ${tools.result.tools*.name}"
```

### Getting Help

1. Check the deployment guide for detailed setup instructions
2. Run `./quick_setup.sh` for automated diagnostics
3. Review MCP server logs in `moqui/runtime/logs/`
4. Test with basic client first, then advanced patterns

---

**Ready to integrate AI with your business data? Start with `./quick_setup.sh`!** 🚀
