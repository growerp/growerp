# MCP Server Usage Examples and Patterns

This document provides comprehensive examples of how to use the GrowERP MCP Server with various clients and integration patterns.

## Basic Usage Examples

### 1. cURL Examples

#### Authentication and Setup
```bash
# Get API key for authentication
API_KEY=$(curl -s -X POST "http://localhost:8080/rest/s1/mcp/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "login",
    "params": {
      "username": "test@example.com",
      "password": "qqqqqq9!",
      "classificationId": "AppSupport"
    },
    "id": 1
  }' | jq -r '.result.apiKey')

echo "API Key: $API_KEY"
```

#### Test System Health
```bash
curl -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "ping_system",
      "arguments": {}
    },
    "id": 2
  }' | jq .
```

#### Get Companies
```bash
curl -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_companies",
      "arguments": {"limit": 5}
    },
    "id": 3
  }' | jq .
```

#### Create a Product
```bash
curl -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "create_product",
      "arguments": {
        "productName": "Test Widget",
        "description": "A test product created via MCP",
        "listPrice": 29.99,
        "productTypeEnumId": "PtFinished"
      }
    },
    "id": 4
  }' | jq .
```

#### Create Sales Order
```bash
curl -X POST "http://localhost:8080/rest/s1/mcp/protocol" \
  -H "Content-Type: application/json" \
  -H "api_key: $API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "create_sales_order",
      "arguments": {
        "customerPartyId": "100001",
        "items": [
          {
            "productId": "PROD-001",
            "quantity": 2,
            "price": 29.99
          }
        ]
      }
    },
    "id": 5
  }' | jq .
```

### 2. Groovy Client Examples

#### Basic Groovy MCP Client
```groovy
#!/usr/bin/env groovy
@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('com.fasterxml.jackson.core:jackson-databind:2.15.2')

import org.apache.http.client.methods.HttpPost
import org.apache.http.entity.StringEntity
import org.apache.http.impl.client.HttpClients
import org.apache.http.util.EntityUtils
import com.fasterxml.jackson.databind.ObjectMapper

class BasicMCPClient {
    private String mcpUrl
    private def httpClient
    private ObjectMapper objectMapper
    private String apiKey
    
    BasicMCPClient(String mcpUrl = "http://localhost:8080/rest/s1/mcp/protocol") {
        this.mcpUrl = mcpUrl
        this.httpClient = HttpClients.createDefault()
        this.objectMapper = new ObjectMapper()
    }
    
    // Authenticate and get API key
    def authenticate(String username, String password, String classification = "AppSupport") {
        def loginRequest = [
            jsonrpc: "2.0",
            method: "login",
            params: [
                username: username,
                password: password,
                classificationId: classification
            ],
            id: 1
        ]
        
        def response = makeRawRequest(loginRequest)
        this.apiKey = response.result?.apiKey
        return this.apiKey
    }
    
    // Make authenticated MCP request
    def callTool(String toolName, Map arguments = [:]) {
        if (!apiKey) {
            throw new IllegalStateException("Must authenticate first")
        }
        
        def request = [
            jsonrpc: "2.0",
            method: "tools/call",
            params: [
                name: toolName,
                arguments: arguments
            ],
            id: System.currentTimeMillis()
        ]
        
        return makeAuthenticatedRequest(request)
    }
    
    private def makeAuthenticatedRequest(Map request) {
        def post = new HttpPost("${mcpUrl}")
        post.setHeader("Content-Type", "application/json")
        post.setHeader("api_key", apiKey)
        
        def json = objectMapper.writeValueAsString(request)
        post.setEntity(new StringEntity(json))
        
        def response = httpClient.execute(post)
        def responseString = EntityUtils.toString(response.getEntity())
        return objectMapper.readValue(responseString, Map.class)
    }
    
    private def makeRawRequest(Map request) {
        def post = new HttpPost("http://localhost:8080/rest/s1/mcp/auth/login")
        post.setHeader("Content-Type", "application/json")
        
        def json = objectMapper.writeValueAsString(request)
        post.setEntity(new StringEntity(json))
        
        def response = httpClient.execute(post)
        def responseString = EntityUtils.toString(response.getEntity())
        return objectMapper.readValue(responseString, Map.class)
    }
}

// Usage example
def client = new BasicMCPClient()

// Authenticate
def apiKey = client.authenticate("test@example.com", "qqqqqq9!")
println "Authenticated with API key: ${apiKey}"

// Test system health
def healthResponse = client.callTool("ping_system")
println "System health: ${healthResponse}"

// Get companies
def companiesResponse = client.callTool("get_companies", [limit: 5])
println "Companies: ${companiesResponse}"

// Create a product
def productResponse = client.callTool("create_product", [
    productName: "Groovy Widget",
    description: "Created from Groovy client",
    listPrice: 39.99
])
println "Product created: ${productResponse}"
```

#### Advanced Groovy DSL Pattern
```groovy
#!/usr/bin/env groovy
@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('com.fasterxml.jackson.core:jackson-databind:2.15.2')

// DSL-style MCP client for fluent operations
class MCPBusinessDSL {
    private BasicMCPClient client
    private Map context = [:]
    
    MCPBusinessDSL(BasicMCPClient client) {
        this.client = client
    }
    
    // Business entity operations
    def companies(Map filters = [:]) {
        def response = client.callTool("get_companies", filters)
        context.companies = response.result?.data
        return this
    }
    
    def users(Map filters = [:]) {
        def response = client.callTool("get_users", filters)
        context.users = response.result?.data
        return this
    }
    
    def products(Map filters = [:]) {
        def response = client.callTool("get_products", filters)
        context.products = response.result?.data
        return this
    }
    
    def orders(Map filters = [:]) {
        def response = client.callTool("get_orders", filters)
        context.orders = response.result?.data
        return this
    }
    
    // Business operations
    def createSalesOrder(String customerId, List items) {
        def response = client.callTool("create_sales_order", [
            customerPartyId: customerId,
            items: items
        ])
        context.lastOrder = response.result?.data
        return this
    }
    
    def createInvoice(String partyId, String invoiceType, List items) {
        def response = client.callTool("create_invoice", [
            partyId: partyId,
            invoiceType: invoiceType,
            items: items
        ])
        context.lastInvoice = response.result?.data
        return this
    }
    
    // System operations
    def ping() {
        def response = client.callTool("ping_system")
        context.systemStatus = response.result
        return this
    }
    
    def financialSummary(String period = "month") {
        def response = client.callTool("get_financial_summary", [period: period])
        context.financialSummary = response.result?.data
        return this
    }
    
    // Get accumulated context
    def getResults() {
        return context
    }
}

// Usage with DSL
def client = new BasicMCPClient()
client.authenticate("test@example.com", "qqqqqq9!")

def business = new MCPBusinessDSL(client)

// Chain operations fluently
def results = business
    .ping()
    .companies(limit: 10)
    .products(limit: 5)
    .financialSummary("quarter")
    .getResults()

println "Business Overview:"
println "System Status: ${results.systemStatus?.text}"
println "Companies: ${results.companies?.size()} found"
println "Products: ${results.products?.size()} found"
println "Financial Summary: ${results.financialSummary}"
```

### 3. Python Client Examples

#### Simple Python MCP Client
```python
import requests
import json
from typing import Dict, Any, Optional

class GrowERPMCPClient:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.mcp_endpoint = f"{base_url}/rest/s1/mcp/protocol"
        self.auth_endpoint = f"{base_url}/rest/s1/mcp/auth/login"
        self.api_key: Optional[str] = None
        self.session = requests.Session()
    
    def authenticate(self, username: str, password: str, classification: str = "AppSupport") -> str:
        """Authenticate and get API key"""
        login_request = {
            "jsonrpc": "2.0",
            "method": "login",
            "params": {
                "username": username,
                "password": password,
                "classificationId": classification
            },
            "id": 1
        }
        
        response = self.session.post(self.auth_endpoint, json=login_request)
        response.raise_for_status()
        
        result = response.json()
        self.api_key = result.get("result", {}).get("apiKey")
        
        if not self.api_key:
            raise ValueError("Authentication failed - no API key received")
        
        return self.api_key
    
    def call_tool(self, tool_name: str, arguments: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute a tool via MCP protocol"""
        if not self.api_key:
            raise ValueError("Must authenticate first")
        
        request = {
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": arguments or {}
            },
            "id": 2
        }
        
        headers = {
            "Content-Type": "application/json",
            "api_key": self.api_key
        }
        
        response = self.session.post(self.mcp_endpoint, json=request, headers=headers)
        response.raise_for_status()
        
        return response.json()
    
    def list_tools(self) -> Dict[str, Any]:
        """Get available tools"""
        if not self.api_key:
            raise ValueError("Must authenticate first")
        
        request = {
            "jsonrpc": "2.0",
            "method": "tools/list",
            "params": {},
            "id": 3
        }
        
        headers = {"Content-Type": "application/json", "api_key": self.api_key}
        response = self.session.post(self.mcp_endpoint, json=request, headers=headers)
        response.raise_for_status()
        
        return response.json()
    
    def get_resources(self) -> Dict[str, Any]:
        """Get available resources"""
        if not self.api_key:
            raise ValueError("Must authenticate first")
        
        request = {
            "jsonrpc": "2.0",
            "method": "resources/list",
            "params": {},
            "id": 4
        }
        
        headers = {"Content-Type": "application/json", "api_key": self.api_key}
        response = self.session.post(self.mcp_endpoint, json=request, headers=headers)
        response.raise_for_status()
        
        return response.json()

# Usage example
def main():
    client = GrowERPMCPClient()
    
    # Authenticate
    api_key = client.authenticate("test@example.com", "qqqqqq9!")
    print(f"Authenticated with API key: {api_key}")
    
    # List available tools
    tools = client.list_tools()
    print(f"Available tools: {[tool['name'] for tool in tools.get('result', {}).get('tools', [])]}")
    
    # Test system health
    health_response = client.call_tool("ping_system")
    print(f"System health: {health_response.get('result', {}).get('text', 'Unknown')}")
    
    # Get companies
    companies_response = client.call_tool("get_companies", {"limit": 5})
    print(f"Companies response: {companies_response}")
    
    # Create a product
    product_response = client.call_tool("create_product", {
        "productName": "Python Widget",
        "description": "Created from Python client",
        "listPrice": 49.99,
        "productTypeEnumId": "PtFinished"
    })
    print(f"Product creation: {product_response}")

if __name__ == "__main__":
    main()
```

#### Async Python Client with AI Integration
```python
import asyncio
import aiohttp
import json
from typing import Dict, Any, List

class AsyncGrowERPMCPClient:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.mcp_endpoint = f"{base_url}/rest/s1/mcp/protocol"
        self.auth_endpoint = f"{base_url}/rest/s1/mcp/auth/login"
        self.api_key: str = None
        self.session: aiohttp.ClientSession = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def authenticate(self, username: str, password: str) -> str:
        """Async authentication"""
        login_request = {
            "jsonrpc": "2.0",
            "method": "login",
            "params": {
                "username": username,
                "password": password,
                "classificationId": "AppSupport"
            },
            "id": 1
        }
        
        async with self.session.post(self.auth_endpoint, json=login_request) as response:
            result = await response.json()
            self.api_key = result.get("result", {}).get("apiKey")
            return self.api_key
    
    async def call_tool(self, tool_name: str, arguments: Dict[str, Any] = None) -> Dict[str, Any]:
        """Async tool execution"""
        request = {
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": arguments or {}
            },
            "id": 2
        }
        
        headers = {
            "Content-Type": "application/json",
            "api_key": self.api_key
        }
        
        async with self.session.post(self.mcp_endpoint, json=request, headers=headers) as response:
            return await response.json()
    
    async def batch_tools(self, tool_calls: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Execute multiple tools concurrently"""
        tasks = []
        for call in tool_calls:
            task = self.call_tool(call['name'], call.get('arguments', {}))
            tasks.append(task)
        
        return await asyncio.gather(*tasks)

# AI Integration Example with OpenAI
async def ai_business_analysis():
    async with AsyncGrowERPMCPClient() as client:
        # Authenticate
        await client.authenticate("test@example.com", "qqqqqq9!")
        
        # Gather business data concurrently
        business_calls = [
            {"name": "ping_system"},
            {"name": "get_companies", "arguments": {"limit": 10}},
            {"name": "get_products", "arguments": {"limit": 5}},
            {"name": "get_financial_summary", "arguments": {"period": "month"}}
        ]
        
        results = await client.batch_tools(business_calls)
        
        # Prepare context for AI
        context = {
            "system_health": results[0].get("result", {}).get("text", ""),
            "companies": results[1].get("result", {}).get("text", ""),
            "products": results[2].get("result", {}).get("text", ""),
            "financials": results[3].get("result", {}).get("text", "")
        }
        
        return context

# Run async example
async def main():
    context = await ai_business_analysis()
    print("Business Context for AI:")
    for key, value in context.items():
        print(f"{key}: {value[:200]}...")

if __name__ == "__main__":
    asyncio.run(main())
```

### 4. Node.js/JavaScript Examples

#### Express.js MCP Proxy Server
```javascript
// mcp-proxy-server.js
const express = require('express');
const axios = require('axios');
const app = express();

app.use(express.json());

class MCPProxy {
    constructor(mcpUrl = 'http://localhost:8080/rest/s1/mcp/protocol') {
        this.mcpUrl = mcpUrl;
        this.authUrl = 'http://localhost:8080/rest/s1/mcp/auth/login';
        this.apiKey = null;
    }
    
    async authenticate(username, password) {
        try {
            const response = await axios.post(this.authUrl, {
                jsonrpc: "2.0",
                method: "login",
                params: {
                    username,
                    password,
                    classificationId: "AppSupport"
                },
                id: 1
            });
            
            this.apiKey = response.data.result?.apiKey;
            return this.apiKey;
        } catch (error) {
            throw new Error(`Authentication failed: ${error.message}`);
        }
    }
    
    async callTool(toolName, arguments = {}) {
        if (!this.apiKey) {
            throw new Error('Must authenticate first');
        }
        
        try {
            const response = await axios.post(this.mcpUrl, {
                jsonrpc: "2.0",
                method: "tools/call",
                params: {
                    name: toolName,
                    arguments
                },
                id: Date.now()
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'api_key': this.apiKey
                }
            });
            
            return response.data;
        } catch (error) {
            throw new Error(`Tool execution failed: ${error.message}`);
        }
    }
}

const mcpProxy = new MCPProxy();

// Authentication endpoint
app.post('/auth', async (req, res) => {
    try {
        const { username, password } = req.body;
        const apiKey = await mcpProxy.authenticate(username, password);
        res.json({ success: true, apiKey });
    } catch (error) {
        res.status(401).json({ success: false, error: error.message });
    }
});

// Tool execution endpoint
app.post('/tool/:toolName', async (req, res) => {
    try {
        const { toolName } = req.params;
        const arguments = req.body;
        
        const result = await mcpProxy.callTool(toolName, arguments);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Business workflow endpoints
app.get('/business/overview', async (req, res) => {
    try {
        const [health, companies, products, financial] = await Promise.all([
            mcpProxy.callTool('ping_system'),
            mcpProxy.callTool('get_companies', { limit: 10 }),
            mcpProxy.callTool('get_products', { limit: 5 }),
            mcpProxy.callTool('get_financial_summary', { period: 'month' })
        ]);
        
        res.json({
            systemHealth: health.result,
            companies: companies.result,
            products: products.result,
            financialSummary: financial.result
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(3000, () => {
    console.log('MCP Proxy Server running on port 3000');
});
```

#### React Frontend Integration
```javascript
// MCPClient.js - React hook for MCP integration
import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';

export const useMCPClient = (baseUrl = 'http://localhost:3000') => {
    const [authenticated, setAuthenticated] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    
    const authenticate = useCallback(async (username, password) => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await axios.post(`${baseUrl}/auth`, {
                username,
                password
            });
            
            if (response.data.success) {
                setAuthenticated(true);
                localStorage.setItem('mcpApiKey', response.data.apiKey);
            }
        } catch (err) {
            setError(err.response?.data?.error || 'Authentication failed');
        } finally {
            setLoading(false);
        }
    }, [baseUrl]);
    
    const callTool = useCallback(async (toolName, arguments = {}) => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await axios.post(`${baseUrl}/tool/${toolName}`, arguments);
            return response.data;
        } catch (err) {
            setError(err.response?.data?.error || 'Tool execution failed');
            throw err;
        } finally {
            setLoading(false);
        }
    }, [baseUrl]);
    
    const getBusinessOverview = useCallback(async () => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await axios.get(`${baseUrl}/business/overview`);
            return response.data;
        } catch (err) {
            setError(err.response?.data?.error || 'Failed to get business overview');
            throw err;
        } finally {
            setLoading(false);
        }
    }, [baseUrl]);
    
    return {
        authenticated,
        loading,
        error,
        authenticate,
        callTool,
        getBusinessOverview
    };
};

// BusinessDashboard.jsx - React component using MCP
import React, { useState, useEffect } from 'react';
import { useMCPClient } from './MCPClient';

const BusinessDashboard = () => {
    const { authenticated, loading, error, authenticate, getBusinessOverview } = useMCPClient();
    const [businessData, setBusinessData] = useState(null);
    const [credentials, setCredentials] = useState({
        username: 'test@example.com',
        password: 'qqqqqq9!'
    });
    
    const handleLogin = async (e) => {
        e.preventDefault();
        await authenticate(credentials.username, credentials.password);
    };
    
    const loadBusinessData = async () => {
        try {
            const data = await getBusinessOverview();
            setBusinessData(data);
        } catch (err) {
            console.error('Failed to load business data:', err);
        }
    };
    
    useEffect(() => {
        if (authenticated) {
            loadBusinessData();
        }
    }, [authenticated]);
    
    if (!authenticated) {
        return (
            <div className="login-form">
                <h2>GrowERP MCP Login</h2>
                <form onSubmit={handleLogin}>
                    <input
                        type="email"
                        placeholder="Username"
                        value={credentials.username}
                        onChange={(e) => setCredentials({...credentials, username: e.target.value})}
                    />
                    <input
                        type="password"
                        placeholder="Password"
                        value={credentials.password}
                        onChange={(e) => setCredentials({...credentials, password: e.target.value})}
                    />
                    <button type="submit" disabled={loading}>
                        {loading ? 'Authenticating...' : 'Login'}
                    </button>
                </form>
                {error && <div className="error">{error}</div>}
            </div>
        );
    }
    
    return (
        <div className="business-dashboard">
            <h1>Business Dashboard</h1>
            
            {loading && <div>Loading...</div>}
            {error && <div className="error">{error}</div>}
            
            {businessData && (
                <div className="dashboard-content">
                    <div className="card">
                        <h3>System Health</h3>
                        <p>{businessData.systemHealth?.text}</p>
                    </div>
                    
                    <div className="card">
                        <h3>Companies</h3>
                        <p>{businessData.companies?.text}</p>
                    </div>
                    
                    <div className="card">
                        <h3>Products</h3>
                        <p>{businessData.products?.text}</p>
                    </div>
                    
                    <div className="card">
                        <h3>Financial Summary</h3>
                        <p>{businessData.financialSummary?.text}</p>
                    </div>
                </div>
            )}
            
            <button onClick={loadBusinessData}>Refresh Data</button>
        </div>
    );
};

export default BusinessDashboard;
```

## Advanced Integration Patterns

### 1. AI-Powered Business Assistant

#### Business Intelligence Workflow
```python
import openai
from growerp_mcp_client import GrowERPMCPClient

class BusinessAIAssistant:
    def __init__(self, openai_api_key, mcp_client):
        self.openai = openai
        self.openai.api_key = openai_api_key
        self.mcp = mcp_client
    
    async def analyze_business_performance(self):
        # Gather comprehensive business data
        financial_data = await self.mcp.call_tool("get_financial_summary", {"period": "month"})
        order_data = await self.mcp.call_tool("get_orders", {"limit": 50})
        company_data = await self.mcp.call_tool("get_companies", {"limit": 20})
        
        # Create AI prompt with business context
        context = f"""
        Business Performance Analysis Request
        
        Financial Summary: {financial_data.get('result', {}).get('text', '')}
        Recent Orders: {order_data.get('result', {}).get('text', '')}
        Company Portfolio: {company_data.get('result', {}).get('text', '')}
        
        Please analyze this business data and provide:
        1. Key performance insights
        2. Areas of concern or opportunity
        3. Actionable recommendations
        4. Trend analysis
        """
        
        response = await self.openai.ChatCompletion.acreate(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are a business analyst with expertise in ERP systems and financial analysis."},
                {"role": "user", "content": context}
            ]
        )
        
        return response.choices[0].message.content
    
    async def automated_order_processing(self, customer_requirements):
        # AI-powered order creation
        prompt = f"""
        Customer Requirements: {customer_requirements}
        
        Based on these requirements, suggest:
        1. Appropriate products from our catalog
        2. Recommended quantities
        3. Pricing strategy
        4. Delivery timeline
        
        Format as structured data for order creation.
        """
        
        ai_response = await self.openai.ChatCompletion.acreate(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )
        
        # Parse AI response and create actual order
        # (Implementation would parse AI response and call create_sales_order tool)
        
        return ai_response.choices[0].message.content
```

### 2. Automated Testing and Monitoring

#### Comprehensive MCP Testing Framework
```bash
#!/bin/bash
# comprehensive_mcp_test.sh - Complete MCP server validation

set -e

echo "=== Comprehensive MCP Server Testing ==="

# Configuration
MCP_URL="http://localhost:8080/rest/s1/mcp/protocol"
AUTH_URL="http://localhost:8080/rest/s1/mcp/auth/login"
TEST_USERNAME="test@example.com"
TEST_PASSWORD="qqqqqq9!"

# Authenticate and get API key
echo "Step 1: Authentication Test"
API_KEY=$(curl -s -X POST "$AUTH_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"login\",
    \"params\": {
      \"username\": \"$TEST_USERNAME\",
      \"password\": \"$TEST_PASSWORD\",
      \"classificationId\": \"AppSupport\"
    },
    \"id\": 1
  }" | jq -r '.result.apiKey')

if [ "$API_KEY" = "null" ] || [ -z "$API_KEY" ]; then
    echo "❌ Authentication failed"
    exit 1
fi

echo "✅ Authentication successful: ${API_KEY:0:10}..."

# Test all available tools
echo "Step 2: Tool Testing"
TOOLS=(
    "ping_system:{}"
    "get_companies:{\"limit\":5}"
    "get_users:{\"limit\":3}"
    "get_products:{\"limit\":3}"
    "get_orders:{\"limit\":3}"
    "get_financial_summary:{\"period\":\"month\"}"
)

for tool_call in "${TOOLS[@]}"; do
    IFS=':' read -r tool_name tool_args <<< "$tool_call"
    
    echo "Testing tool: $tool_name"
    
    response=$(curl -s -X POST "$MCP_URL" \
      -H "Content-Type: application/json" \
      -H "api_key: $API_KEY" \
      -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"tools/call\",
        \"params\": {
          \"name\": \"$tool_name\",
          \"arguments\": $tool_args
        },
        \"id\": $(date +%s)
      }")
    
    if echo "$response" | jq -e '.error' > /dev/null; then
        echo "❌ Tool $tool_name failed: $(echo "$response" | jq -r '.error.message')"
    else
        echo "✅ Tool $tool_name succeeded"
    fi
done

# Performance testing
echo "Step 3: Performance Testing"
start_time=$(date +%s%3N)

for i in {1..10}; do
    curl -s -X POST "$MCP_URL" \
      -H "Content-Type: application/json" \
      -H "api_key: $API_KEY" \
      -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"tools/call\",
        \"params\": {
          \"name\": \"ping_system\",
          \"arguments\": {}
        },
        \"id\": $i
      }" > /dev/null
done

end_time=$(date +%s%3N)
duration=$((end_time - start_time))
avg_response=$((duration / 10))

echo "✅ Performance test completed: ${avg_response}ms average response time"

# Security testing
echo "Step 4: Security Testing"

# Test without API key
no_auth_response=$(curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"get_companies\",
      \"arguments\": {}
    },
    \"id\": 999
  }")

if echo "$no_auth_response" | jq -e '.error' > /dev/null; then
    echo "✅ Security test passed: Unauthenticated request properly rejected"
else
    echo "❌ Security test failed: Unauthenticated request was allowed"
fi

echo "=== Testing Complete ==="
```

This comprehensive examples document provides practical, real-world usage patterns for the GrowERP MCP Server across multiple programming languages and integration scenarios. Each example is complete and can be used as-is or adapted for specific requirements.
