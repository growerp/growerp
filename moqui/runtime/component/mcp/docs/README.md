# GrowERP MCP Server Documentation

Welcome to the GrowERP Model Context Protocol (MCP) Server documentation. This server provides AI agents and development tools with structured access to GrowERP business data and operations through the standardized MCP protocol.

## Documentation Structure

- **[API Reference](api-reference.md)** - Complete API documentation for all endpoints and services
- **[Architecture Guide](architecture.md)** - Technical architecture and component design
- **[Quick Start Guide](quick-start.md)** - Get up and running quickly
- **[Configuration Guide](configuration.md)** - Detailed configuration options
- **[Developer Guide](developer-guide.md)** - For developers extending the MCP server
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- **[Examples](examples/)** - Code examples and integration patterns

## What is the GrowERP MCP Server?

The GrowERP MCP Server is a bridge between AI agents and the GrowERP business system. It implements the Model Context Protocol (MCP) specification, allowing AI tools to:

- **Access Business Data**: Query companies, users, products, orders, and other business entities
- **Execute Operations**: Create orders, generate invoices, manage inventory, and perform business workflows
- **Understand Context**: Get entity schemas, service documentation, and business process information
- **Integrate Seamlessly**: Use standardized protocols for reliable AI-business system integration

## Key Features

### 🔌 **Protocol Compliance**
- Full MCP specification (2024-11-05) implementation
- JSON-RPC 2.0 communication protocol
- RESTful HTTP endpoints for easy integration
- Comprehensive error handling and logging

### 🏢 **Business Integration**
- Direct access to GrowERP/Moqui entities and services
- Real-time business data access
- Transaction support for data integrity
- Security integration with existing authentication

### 🛠️ **Developer Friendly**
- Simple Groovy-based implementation
- Extensible architecture for custom tools and resources
- Comprehensive test suite
- Clear documentation and examples

### 🚀 **Production Ready**
- Built on proven Moqui framework
- Scalable and performant
- Monitoring and health check endpoints
- Configurable security and access controls

## Quick Example

Here's how an AI agent might interact with the MCP server:

```bash
# Check server health
curl http://localhost:8080/rest/s1/mcp/health

# List available tools
curl http://localhost:8080/rest/s1/mcp/tools

# Execute a tool to get companies
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {"limit": 5}
    },
    "id": 1
  }'
```

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AI Agent      │    │   MCP Server     │    │   GrowERP       │
│                 │◄──►│                  │◄──►│                 │
│ - Claude        │    │ - Protocol       │    │ - Moqui Services│
│ - ChatGPT       │    │   Handler        │    │ - Entity Engine │
│ - Custom Tools  │    │ - Resource Mgr   │    │ - Business Logic│
│                 │    │ - Tool Manager   │    │ - Database      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

The MCP server acts as a standardized interface layer, translating MCP protocol requests into Moqui service calls and entity operations.

## Getting Started

1. **Prerequisites**: Ensure you have Moqui 3.0+ and GrowERP installed
2. **Installation**: The MCP server is included as a component in GrowERP
3. **Configuration**: Minimal configuration required - works out of the box
4. **Testing**: Use the provided REST endpoints to verify functionality

For detailed setup instructions, see the [Quick Start Guide](quick-start.md).

## Support and Contributing

- **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/growerp/growerp/issues)
- **Discussions**: Join the community on [GitHub Discussions](https://github.com/growerp/growerp/discussions)
- **Documentation**: Contribute to documentation improvements
- **Code**: Submit pull requests for new features and bug fixes

## License

This project is licensed under the CC0 1.0 Universal License - see the [LICENSE.md](../LICENSE.md) file for details.

---

Ready to get started? Check out the [Quick Start Guide](quick-start.md) or dive into the [API Reference](api-reference.md).
