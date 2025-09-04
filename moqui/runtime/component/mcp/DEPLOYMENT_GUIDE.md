# GrowERP MCP Server Deployment Guide

## Overview
This guide shows how to deploy the GrowERP Model Context Protocol (MCP) Server and integrate it with AI assistants like Claude, ChatGPT, or other MCP-compatible clients.

## 1. Server Deployment

### Option A: Standalone Deployment (Recommended for AI Integration)

#### Step 1: Build and Start Moqui Backend
```bash
cd /home/hans/growerp/moqui

# Build the project
./gradlew build

# Initialize database (if not done already)
java -jar moqui.war load types=seed,seed-initial,install no-run-es

# Start the backend server
java -jar moqui.war no-run-es
```

#### Step 2: Start MCP Server via REST API
```bash
# Create MCP server configuration
curl -X POST "http://localhost:8080/rest/s1/mcp/servers" \
  -H "Content-Type: application/json" \
  -d '{
    "serverId": "main-mcp-server",
    "port": 8081,
    "host": "0.0.0.0",
    "enabled": true,
    "description": "Main GrowERP MCP Server for AI Integration"
  }'

# Start the MCP server
curl -X POST "http://localhost:8080/rest/s1/mcp/servers/main-mcp-server/start"

# Verify server status
curl -X GET "http://localhost:8080/rest/s1/mcp/servers/main-mcp-server/status"
```

#### Step 3: Test MCP Server Connectivity
```bash
# Test MCP server health
curl -X GET "http://localhost:8081/" \
  -H "Accept: application/json"

# Should return server information and capabilities
```

### Option B: Docker Deployment

#### Create Docker Configuration
```bash
# Add to docker/docker-compose.yaml
cat >> docker/docker-compose.yaml << 'EOF'
  mcp-server:
    build:
      context: ../moqui
      dockerfile: Dockerfile
    ports:
      - "8081:8081"
    environment:
      - MCP_SERVER_PORT=8081
      - MCP_SERVER_HOST=0.0.0.0
    depends_on:
      - moqui
    networks:
      - growerp-network
EOF
```

## 2. AI Client Integration

### For Claude Desktop (Anthropic)

#### Step 1: Install Claude Desktop
Download from: https://claude.ai/download

#### Step 2: Configure MCP Server in Claude
Create or edit `~/.config/claude-desktop/config.json`:

```json
{
  "mcp": {
    "servers": {
      "growerp": {
        "command": "npx",
        "args": [
          "@modelcontextprotocol/server-stdio",
          "--url", "http://localhost:8081"
        ],
        "env": {
          "MCP_SERVER_URL": "http://localhost:8081"
        }
      }
    }
  }
}
```

#### Alternative: Direct Socket Connection
```json
{
  "mcp": {
    "servers": {
      "growerp": {
        "command": "node",
        "args": [
          "-e",
          "const net = require('net'); const client = net.createConnection(8081, 'localhost'); process.stdin.pipe(client); client.pipe(process.stdout);"
        ]
      }
    }
  }
}
```


### For Groovy Integration (Recommended for GrowERP)

#### Native Groovy MCP Client

GrowERP provides native Groovy integration that matches your existing technology stack:

```groovy
#!/usr/bin/env groovy
@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('com.fasterxml.jackson.core:jackson-databind:2.15.2')

// Basic client usage
AdvancedMCPClient client = new AdvancedMCPClient("http://localhost:8081")

// Initialize connection
client.makeRequest("initialize", [
    protocolVersion: "2024-11-05",
    clientInfo: [name: "growerp-integration"]
])

// Use Groovy DSL for tool operations
def businessData = client.tools {
    ping()                              // Check system health
    companies(limit: 10)               // Get company data
    users(limit: 5)                    // Get user data
    custom("get_reports", [type: "sales"]) // Custom tool call
}

println "Business Data: ${businessData.results}"
```

#### AI Assistant with Groovy DSL

```groovy
// Full AI assistant implementation
BusinessAIAssistant assistant = new BusinessAIAssistant()

// Process natural language queries
def response = assistant.processQuery("What's the current status of my business?")

println "AI Response: ${response.aiResponse}"
println "Context: ${response.context.keySet()}"

// Create custom AI prompts
def prompt = new AIPromptBuilder()
    .withSystemContext("GrowERP Business Management")
    .withBusinessData(response.context)
    .withQuery("Provide recommendations for growth")
    .withInstructions("Focus on actionable insights")
    .build()
```

#### Running Groovy Examples

```bash
# Basic Groovy client
groovy test_mcp_client.groovy

# Advanced patterns and DSL examples
groovy advanced_mcp_examples.groovy

# Quick setup with Groovy
./quick_setup.sh
```

#### Integration with Existing Groovy/Moqui Code

```groovy
// In your existing Moqui services
import org.moqui.context.ExecutionContext

class BusinessAnalysisService {
    static void analyzeWithAI(ExecutionContext ec) {
        // Get MCP client
        def mcpClient = new AdvancedMCPClient()
        
        // Use trait for MCP operations
        def aiAssistant = new BusinessAIAssistant() implements MCPEnabled
        
        // Process business query
        def analysis = aiAssistant.processQuery("Analyze current business metrics")
        
        // Store results in Moqui entity
        ec.entity.makeValue("AIAnalysis")
            .set("analysisText", analysis.aiResponse)
            .set("contextData", analysis.context.toString())
            .create()
    }
}
```

### For ChatGPT/OpenAI Integration

#### Using OpenAI API with MCP
```python
# install: pip install openai requests
import openai
import requests
import json

class GrowERPMCPClient:
    def __init__(self, mcp_url="http://localhost:8081"):
        self.mcp_url = mcp_url
        self.session = requests.Session()
        self.initialize_mcp()
    
    def initialize_mcp(self):
        """Initialize MCP connection"""
        init_request = {
            "jsonrpc": "2.0",
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "clientInfo": {
                    "name": "openai-mcp-client",
                    "version": "1.0.0"
                }
            },
            "id": 1
        }
        
        response = self.session.post(
            self.mcp_url,
            json=init_request,
            headers={"Content-Type": "application/json"}
        )
        return response.json()
    
    def get_tools(self):
        """Get available tools from MCP server"""
        request = {
            "jsonrpc": "2.0",
            "method": "tools/list",
            "params": {},
            "id": 2
        }
        
        response = self.session.post(
            self.mcp_url,
            json=request,
            headers={"Content-Type": "application/json"}
        )
        return response.json()
    
    def call_tool(self, tool_name, arguments):
        """Execute a tool via MCP"""
        request = {
            "jsonrpc": "2.0",
            "method": "tools/call", 
            "params": {
                "name": tool_name,
                "arguments": arguments
            },
            "id": 3
        }
        
        response = self.session.post(
            self.mcp_url,
            json=request,
            headers={"Content-Type": "application/json"}
        )
        return response.json()
    
    def get_resources(self):
        """Get available resources"""
        request = {
            "jsonrpc": "2.0",
            "method": "resources/list",
            "params": {},
            "id": 4
        }
        
        response = self.session.post(
            self.mcp_url,
            json=request,
            headers={"Content-Type": "application/json"}
        )
        return response.json()

# Usage example
def main():
    # Initialize MCP client
    mcp = GrowERPMCPClient()
    
    # Initialize OpenAI client
    openai.api_key = "your-openai-api-key"
    
    # Get available tools
    tools_response = mcp.get_tools()
    print("Available tools:", tools_response)
    
    # Example: Ask AI to use GrowERP data
    prompt = """
    I need to check the system status and get a list of companies in GrowERP.
    Use the available MCP tools to fetch this information.
    """
    
    # Check system status
    system_status = mcp.call_tool("ping_system", {})
    print("System Status:", system_status)
    
    # Get companies
    companies = mcp.call_tool("get_companies", {"limit": 10})
    print("Companies:", companies)
    
    # Use this data in OpenAI request
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are an assistant with access to GrowERP data via MCP."},
            {"role": "user", "content": prompt},
            {"role": "assistant", "content": f"System Status: {system_status}\nCompanies: {companies}"}
        ]
    )
    
    print("AI Response:", response.choices[0].message.content)

if __name__ == "__main__":
    main()
```

### For Custom AI Integration

#### Simple Node.js MCP Client
```javascript
// mcp-client.js
const WebSocket = require('ws');
const net = require('net');

class GrowERPMCPClient {
    constructor(host = 'localhost', port = 8081) {
        this.host = host;
        this.port = port;
        this.socket = null;
        this.requestId = 1;
    }
    
    async connect() {
        return new Promise((resolve, reject) => {
            this.socket = net.createConnection(this.port, this.host);
            
            this.socket.on('connect', () => {
                console.log('Connected to MCP server');
                this.initialize().then(resolve).catch(reject);
            });
            
            this.socket.on('error', reject);
        });
    }
    
    async initialize() {
        const request = {
            jsonrpc: "2.0",
            method: "initialize",
            params: {
                protocolVersion: "2024-11-05",
                clientInfo: {
                    name: "nodejs-mcp-client",
                    version: "1.0.0"
                }
            },
            id: this.requestId++
        };
        
        return this.sendRequest(request);
    }
    
    async sendRequest(request) {
        return new Promise((resolve, reject) => {
            const requestStr = JSON.stringify(request) + '\n';
            
            this.socket.once('data', (data) => {
                try {
                    const response = JSON.parse(data.toString());
                    resolve(response);
                } catch (err) {
                    reject(err);
                }
            });
            
            this.socket.write(requestStr);
        });
    }
    
    async getTools() {
        const request = {
            jsonrpc: "2.0",
            method: "tools/list",
            params: {},
            id: this.requestId++
        };
        
        return this.sendRequest(request);
    }
    
    async callTool(name, arguments = {}) {
        const request = {
            jsonrpc: "2.0",
            method: "tools/call",
            params: { name, arguments },
            id: this.requestId++
        };
        
        return this.sendRequest(request);
    }
    
    disconnect() {
        if (this.socket) {
            this.socket.end();
        }
    }
}

// Usage
async function main() {
    const client = new GrowERPMCPClient();
    
    try {
        await client.connect();
        
        // Get available tools
        const tools = await client.getTools();
        console.log('Available tools:', JSON.stringify(tools, null, 2));
        
        // Call a tool
        const systemStatus = await client.callTool('ping_system');
        console.log('System status:', JSON.stringify(systemStatus, null, 2));
        
        // Get companies
        const companies = await client.callTool('get_companies', { limit: 5 });
        console.log('Companies:', JSON.stringify(companies, null, 2));
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        client.disconnect();
    }
}

main();
```

## 3. Example AI Interactions

### Example 1: System Health Check
```
AI Prompt: "Check the health of the GrowERP system and report on its status"

MCP Tool Call: ping_system()
Response: {
  "status": "ok",
  "timestamp": 1693651200000,
  "server": "growerp-mcp-server",
  "moquiVersion": "3.0.0"
}

AI Response: "The GrowERP system is healthy and operational. The MCP server is running version 3.0.0 and responded successfully at timestamp 1693651200000."
```

### Example 2: Business Data Query
```
AI Prompt: "Show me the top 5 companies in our system and their basic information"

MCP Tool Call: get_companies({"limit": 5})
Response: {
  "isError": false,
  "content": [
    {
      "type": "text", 
      "text": "Found 5 companies:\n1. Acme Corp (ID: ACME-001)\n2. Tech Solutions Inc (ID: TECH-002)..."
    }
  ]
}

AI Response: "Here are the top 5 companies in your GrowERP system:
1. Acme Corp (ID: ACME-001)
2. Tech Solutions Inc (ID: TECH-002)
..."
```

### Example 3: Resource Exploration
```
AI Prompt: "What data and resources are available in the GrowERP system?"

MCP Tool Call: resources/list()
Response: {
  "resources": [
    {
      "uri": "growerp://entities/Party",
      "name": "Party Entities",
      "description": "Access to party/company data",
      "mimeType": "application/json"
    },
    ...
  ]
}

AI Response: "The GrowERP system provides access to several data resources including Party Entities, System Status, Entity Schemas, and more. You can query company data, system health, and explore the database structure."
```

## 4. Security Considerations

### Authentication Setup
```bash
# Set up API authentication for production
curl -X POST "http://localhost:8080/rest/s1/mcp/auth/create-token" \
  -H "Content-Type: application/json" \
  -d '{
    "clientName": "ai-assistant",
    "permissions": ["read:entities", "execute:tools", "read:resources"]
  }'
```

### Network Security
- Use HTTPS/WSS in production
- Implement proper firewall rules
- Consider VPN for remote access
- Use authentication tokens

## 5. Monitoring and Logging

### Health Check Endpoint
```bash
# Monitor server health
curl -X GET "http://localhost:8081/health"
```

### Logging Configuration
Add to `MoquiDevConf.xml`:
```xml
<logger name="com.mcp" level="INFO"/>
```

## 6. Troubleshooting

### Common Issues
1. **Connection Refused**: Check if MCP server is running on correct port
2. **Authentication Errors**: Verify API credentials and permissions
3. **Tool Execution Failures**: Check Moqui backend connectivity
4. **Resource Access Denied**: Verify entity access permissions

### Debug Commands
```bash
# Check MCP server status
curl -X GET "http://localhost:8080/rest/s1/mcp/servers"

# Test direct MCP communication
echo '{"jsonrpc":"2.0","method":"ping","params":{},"id":1}' | nc localhost 8081

# View server logs
tail -f runtime/log/moqui.log | grep MCP
```

## Conclusion

The GrowERP MCP Server provides a standardized way for AI assistants to interact with your business data. Follow this guide to deploy and integrate with your preferred AI platform for powerful business automation and insights.
