# MCP Server Examples and Test Files

This directory contains practical examples, test clients, and integration patterns for the GrowERP MCP Server.

## 📁 Example Files Overview

### 🧪 Test Clients and Authentication
- **`test_mcp_client.groovy`** - Comprehensive Groovy test client with full MCP protocol support
- **`test_mcp_client_simple.groovy`** - Simplified Groovy client for basic testing
- **`test_mcp_auth.groovy`** - Authentication testing and validation scripts

### 🖥️ Server Implementations  
- **`mcp-stdio-server.groovy`** - Full STDIO-based MCP server for Claude Desktop integration
- **`mcp-stdio-server-simple.groovy`** - Simplified STDIO server implementation
- **`advanced_mcp_examples.groovy`** - Advanced usage patterns and DSL examples

## 🚀 Quick Usage

### Basic Testing
```bash
# Test basic MCP functionality
cd /home/hans/growerp/moqui/runtime/component/mcp
groovy docs/examples/test_mcp_client_simple.groovy

# Test authentication
groovy docs/examples/test_mcp_auth.groovy
```

### Claude Desktop Integration
```bash
# Run STDIO server for Claude Desktop
groovy docs/examples/mcp-stdio-server.groovy
```

### Advanced Patterns
```bash
# Explore advanced Groovy DSL patterns
groovy docs/examples/advanced_mcp_examples.groovy
```

## 📚 Related Documentation

- **[Examples Guide](../examples.md)** - Comprehensive examples in multiple languages
- **[Quick Start Guide](../quick-start.md)** - Basic setup and testing
- **[API Reference](../api-reference.md)** - Complete API documentation
- **[Security Guide](../security-guide.md)** - Authentication and security setup

## 🛠️ Running Examples

### Prerequisites
1. Ensure Moqui is running:
   ```bash
   cd /home/hans/growerp/moqui
   java -jar moqui.war no-run-es
   ```

2. Verify MCP server is accessible:
   ```bash
   curl http://localhost:8080/rest/s1/mcp/health
   ```

### Authentication Setup
Most examples use these test credentials:
- **Username**: `test@example.com`
- **Password**: `qqqqqq9!`
- **Classification**: `AppSupport`

### Example Execution
```bash
# From the MCP component root
cd /home/hans/growerp/moqui/runtime/component/mcp

# Run any example
groovy docs/examples/[example_file.groovy]
```

## 🔧 Customization

These examples can be customized for your specific needs:

1. **Modify Endpoints**: Change URLs in client configurations
2. **Add Custom Tools**: Extend examples with your specific business tools
3. **Authentication**: Update credentials for your environment
4. **Integration**: Adapt patterns for your AI platform or application

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/growerp/growerp/issues)
- **Documentation**: See parent directory for complete guides
- **Community**: [GitHub Discussions](https://github.com/growerp/growerp/discussions)
