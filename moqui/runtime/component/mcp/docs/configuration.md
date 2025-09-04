# Configuration Guide

Complete guide to configuring and customizing the GrowERP MCP Server.

## Overview

The GrowERP MCP Server can be configured at multiple levels to customize its behavior, security, performance, and feature set. This guide covers all configuration options and provides examples for common scenarios.

## Configuration Hierarchy

The configuration system follows this hierarchy (higher levels override lower levels):

1. **Environment Variables** (highest priority)
2. **Moqui Configuration Properties**
3. **Component Configuration Files**
4. **Service Definition Defaults**
5. **Built-in Defaults** (lowest priority)

## Component Configuration

### component.xml

The main component configuration file defines dependencies, metadata, and initialization parameters.

**Location**: `/moqui/runtime/component/growerp-mcp-server/component.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<moqui-component name="growerp-mcp-server" version="1.0.0"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/moqui-conf-3.xsd">
    
    <!-- Component metadata -->
    <description>GrowERP Model Context Protocol Server</description>
    <author>GrowERP Team</author>
    
    <!-- Dependencies -->
    <depends-on name="growerp"/>
    
    <!-- Configuration parameters -->
    <parameter name="mcp.server.enabled" value="true"/>
    <parameter name="mcp.server.port" value="8080"/>
    <parameter name="mcp.server.host" value="localhost"/>
    <parameter name="mcp.protocol.version" value="2024-11-05"/>
    
    <!-- Feature flags -->
    <parameter name="mcp.features.tools.enabled" value="true"/>
    <parameter name="mcp.features.resources.enabled" value="true"/>
    <parameter name="mcp.features.prompts.enabled" value="false"/>
    <parameter name="mcp.features.logging.enabled" value="true"/>
    
    <!-- Security configuration -->
    <parameter name="mcp.security.auth.required" value="false"/>
    <parameter name="mcp.security.cors.enabled" value="true"/>
    <parameter name="mcp.security.rate.limit.enabled" value="false"/>
    
    <!-- Performance tuning -->
    <parameter name="mcp.cache.tools.ttl" value="300"/>
    <parameter name="mcp.cache.resources.ttl" value="300"/>
    <parameter name="mcp.request.timeout" value="30"/>
    
</moqui-component>
```

### Configuration Parameters

#### Server Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mcp.server.enabled` | `true` | Enable/disable MCP server |
| `mcp.server.port` | `8080` | Server port (inherited from Moqui) |
| `mcp.server.host` | `localhost` | Server host binding |
| `mcp.protocol.version` | `2024-11-05` | MCP protocol version |

#### Feature Flags

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mcp.features.tools.enabled` | `true` | Enable tool functionality |
| `mcp.features.resources.enabled` | `true` | Enable resource functionality |
| `mcp.features.prompts.enabled` | `false` | Enable prompt functionality |
| `mcp.features.logging.enabled` | `true` | Enable MCP-specific logging |

#### Security Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mcp.security.auth.required` | `false` | Require authentication |
| `mcp.security.cors.enabled` | `true` | Enable CORS headers |
| `mcp.security.rate.limit.enabled` | `false` | Enable rate limiting |
| `mcp.security.allowed.origins` | `*` | Allowed CORS origins |

#### Performance Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mcp.cache.tools.ttl` | `300` | Tool cache TTL (seconds) |
| `mcp.cache.resources.ttl` | `300` | Resource cache TTL (seconds) |
| `mcp.request.timeout` | `30` | Request timeout (seconds) |
| `mcp.max.concurrent.requests` | `100` | Max concurrent requests |

## Environment Variables

Override any configuration parameter using environment variables with the `MOQUI_CONF_` prefix:

```bash
# Enable authentication
export MOQUI_CONF_mcp_security_auth_required=true

# Set custom timeout
export MOQUI_CONF_mcp_request_timeout=60

# Disable tools feature
export MOQUI_CONF_mcp_features_tools_enabled=false
```

## Service Configuration

### McpServerServices.xml

Service-level configuration for MCP operations.

**Location**: `/service/McpServerServices.xml`

```xml
<services xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/service-definition-3.xsd">

    <!-- Main MCP request handler -->
    <service name="mcpHandleRequest" type="script"
             location="component://growerp-mcp-server/service/McpServerServices.xml#mcpHandleRequest">
        <description>Handle MCP JSON-RPC requests</description>
        
        <!-- Configuration parameters -->
        <parameter name="enableLogging" default-value="true"/>
        <parameter name="validateRequests" default-value="true"/>
        <parameter name="maxRequestSize" default-value="1048576"/> <!-- 1MB -->
        
        <in-parameters>
            <parameter name="request" type="String" required="true"/>
            <parameter name="requestId" type="String"/>
        </in-parameters>
        
        <out-parameters>
            <parameter name="response" type="String"/>
            <parameter name="statusCode" type="Integer" default="200"/>
        </out-parameters>
    </service>

    <!-- Tool management services -->
    <service name="mcpListTools" type="script"
             location="component://growerp-mcp-server/service/McpServerServices.xml#mcpListTools">
        <description>List available MCP tools</description>
        
        <parameter name="includeDisabled" default-value="false"/>
        <parameter name="categoryFilter" type="String"/>
        
        <out-parameters>
            <parameter name="tools" type="List"/>
        </out-parameters>
    </service>

    <!-- Resource management services -->
    <service name="mcpListResources" type="script"
             location="component://growerp-mcp-server/service/McpServerServices.xml#mcpListResources">
        <description>List available MCP resources</description>
        
        <parameter name="includeRestricted" default-value="false"/>
        <parameter name="uriPattern" type="String"/>
        
        <out-parameters>
            <parameter name="resources" type="List"/>
        </out-parameters>
    </service>

</services>
```

## Screen Configuration

### McpServer.xml

REST endpoint configuration and request routing.

**Location**: `/screen/McpServer.xml`

```xml
<screen xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/xml-screen-3.xsd"
        default-menu-title="MCP Server" default-menu-index="99"
        standalone="true" require-authentication="false">

    <!-- MCP JSON-RPC endpoint -->
    <transition name="mcp" method="post" read-only="false">
        <parameter name="request"/>
        
        <!-- Request validation -->
        <condition>
            <expression>request</expression>
        </condition>
        
        <!-- Service call -->
        <service-call name="mcpHandleRequest" 
                      in-map="[request: request]" 
                      out-map="context"/>
        
        <!-- Response configuration -->
        <default-response type="plain" 
                         encode="false"
                         content-type="application/json">
            <parameter name="responseText" from="response"/>
        </default-response>
        
        <!-- Error handling -->
        <error-response type="plain"
                       content-type="application/json">
            <parameter name="responseText" 
                      value='{"jsonrpc":"2.0","error":{"code":-32603,"message":"Internal error"},"id":null}'/>
        </error-response>
    </transition>

    <!-- Health check endpoint -->
    <transition name="health" method="get" read-only="true">
        <actions>
            <set field="healthStatus" from="[
                status: 'healthy',
                timestamp: System.currentTimeMillis(),
                version: '1.0.0'
            ]"/>
            <script>
                ec.web.response.addHeader('Content-Type', 'application/json')
                ec.web.response.writer.write(groovy.json.JsonBuilder(healthStatus).toString())
            </script>
        </actions>
        <default-response type="none"/>
    </transition>

    <!-- Tools listing endpoint -->
    <transition name="tools" method="get" read-only="true">
        <service-call name="mcpListTools" out-map="context"/>
        <default-response type="plain" encode="false" content-type="application/json">
            <parameter name="responseText" from="groovy.json.JsonBuilder([tools: tools]).toString()"/>
        </default-response>
    </transition>

    <!-- Resources listing endpoint -->
    <transition name="resources" method="get" read-only="true">
        <service-call name="mcpListResources" out-map="context"/>
        <default-response type="plain" encode="false" content-type="application/json">
            <parameter name="responseText" from="groovy.json.JsonBuilder([resources: resources]).toString()"/>
        </default-response>
    </transition>

    <widgets>
        <label text="GrowERP MCP Server" type="h1"/>
        <label text="Model Context Protocol Server for GrowERP" type="p"/>
    </widgets>
</screen>
```

## Tool Configuration

### Built-in Tools

Configure built-in tools through the tool manager:

```groovy
// In McpToolManagerSimple.groovy
class McpToolManagerSimple {
    
    // Tool configuration
    private static final Map TOOL_CONFIG = [
        ping_system: [
            enabled: true,
            timeout: 5000,
            description: "Check system health"
        ],
        get_companies: [
            enabled: true,
            timeout: 10000,
            maxResults: 100,
            description: "Get list of companies"
        ]
    ]
    
    // Tool registration
    def registerTools() {
        TOOL_CONFIG.each { name, config ->
            if (config.enabled) {
                registerTool(name, config)
            }
        }
    }
}
```

### Custom Tool Configuration

Add custom tools by extending the tool configuration:

```groovy
// Custom tool configuration
private static final Map CUSTOM_TOOLS = [
    get_orders: [
        enabled: true,
        timeout: 15000,
        description: "Retrieve customer orders",
        permissions: ["ORDER_VIEW"],
        inputSchema: [
            type: "object",
            properties: [
                customerId: [type: "string"],
                status: [type: "string"],
                limit: [type: "integer", default: 10]
            ]
        ]
    ]
]
```

## Resource Configuration

### Built-in Resources

Configure built-in resources:

```groovy
// In McpResourceManagerSimple.groovy
class McpResourceManagerSimple {
    
    // Resource configuration
    private static final Map RESOURCE_CONFIG = [
        'growerp://entities/company': [
            enabled: true,
            cache: true,
            permissions: ["ENTITY_VIEW"]
        ],
        'growerp://system/status': [
            enabled: true,
            cache: false,
            refreshInterval: 30
        ]
    ]
}
```

### Custom Resource Configuration

```groovy
// Custom resource configuration
private static final Map CUSTOM_RESOURCES = [
    'growerp://reports/sales': [
        enabled: true,
        cache: true,
        cacheTtl: 300,
        permissions: ["REPORT_VIEW"],
        generator: "SalesReportGenerator"
    ]
]
```

## Security Configuration

### Authentication Setup

Enable authentication by configuring the security parameters:

```xml
<!-- In component.xml -->
<parameter name="mcp.security.auth.required" value="true"/>
<parameter name="mcp.security.auth.method" value="bearer"/>
<parameter name="mcp.security.token.expiry" value="3600"/>
```

```xml
<!-- In McpServer.xml -->
<screen require-authentication="true">
    <transition name="mcp" method="post">
        <!-- Authentication will be enforced -->
    </transition>
</screen>
```

### CORS Configuration

Configure Cross-Origin Resource Sharing:

```xml
<parameter name="mcp.security.cors.enabled" value="true"/>
<parameter name="mcp.security.cors.origins" value="http://localhost:3000,https://app.example.com"/>
<parameter name="mcp.security.cors.methods" value="GET,POST,OPTIONS"/>
<parameter name="mcp.security.cors.headers" value="Content-Type,Authorization"/>
```

### Rate Limiting

Enable rate limiting to prevent abuse:

```xml
<parameter name="mcp.security.rate.limit.enabled" value="true"/>
<parameter name="mcp.security.rate.limit.requests" value="100"/>
<parameter name="mcp.security.rate.limit.window" value="60"/>
<parameter name="mcp.security.rate.limit.strategy" value="sliding-window"/>
```

## Performance Configuration

### Caching Configuration

Configure caching for better performance:

```xml
<!-- Cache settings -->
<parameter name="mcp.cache.enabled" value="true"/>
<parameter name="mcp.cache.tools.ttl" value="300"/>
<parameter name="mcp.cache.resources.ttl" value="300"/>
<parameter name="mcp.cache.max.size" value="1000"/>
<parameter name="mcp.cache.eviction.policy" value="LRU"/>
```

### Connection Pooling

Configure HTTP and database connection pooling:

```xml
<!-- HTTP connection settings -->
<parameter name="mcp.http.pool.size" value="50"/>
<parameter name="mcp.http.pool.timeout" value="30"/>
<parameter name="mcp.http.keep.alive" value="true"/>

<!-- Database connection settings (inherited from Moqui) -->
<parameter name="entity_ds_db_conf.connection_properties.maxActive" value="50"/>
<parameter name="entity_ds_db_conf.connection_properties.maxIdle" value="10"/>
```

### Memory Configuration

Configure memory usage and limits:

```xml
<parameter name="mcp.memory.max.request.size" value="10485760"/> <!-- 10MB -->
<parameter name="mcp.memory.max.response.size" value="10485760"/> <!-- 10MB -->
<parameter name="mcp.memory.buffer.size" value="8192"/>
```

## Logging Configuration

### MCP-Specific Logging

Configure logging for MCP operations:

```xml
<!-- In MoquiConf.xml or log4j2.xml -->
<Configuration>
    <Loggers>
        <!-- MCP Server logging -->
        <Logger name="growerp.mcp" level="INFO" additivity="false">
            <AppenderRef ref="stdout"/>
            <AppenderRef ref="mcpFile"/>
        </Logger>
        
        <!-- Protocol-level debugging -->
        <Logger name="growerp.mcp.protocol" level="DEBUG" additivity="false">
            <AppenderRef ref="mcpProtocolFile"/>
        </Logger>
        
        <!-- Tool execution logging -->
        <Logger name="growerp.mcp.tools" level="INFO" additivity="false">
            <AppenderRef ref="mcpToolsFile"/>
        </Logger>
    </Loggers>
    
    <Appenders>
        <File name="mcpFile" fileName="logs/mcp-server.log">
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </File>
        
        <File name="mcpProtocolFile" fileName="logs/mcp-protocol.log">
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </File>
        
        <File name="mcpToolsFile" fileName="logs/mcp-tools.log">
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </File>
    </Appenders>
</Configuration>
```

### Request/Response Logging

Enable detailed request/response logging:

```xml
<parameter name="mcp.logging.requests.enabled" value="true"/>
<parameter name="mcp.logging.responses.enabled" value="true"/>
<parameter name="mcp.logging.sanitize.sensitive" value="true"/>
<parameter name="mcp.logging.max.body.size" value="4096"/>
```

## Environment-Specific Configurations

### Development Environment

**File**: `conf/development.properties`
```properties
# Development-specific MCP settings
mcp.server.enabled=true
mcp.security.auth.required=false
mcp.security.cors.enabled=true
mcp.security.cors.origins=*
mcp.logging.requests.enabled=true
mcp.logging.responses.enabled=true
mcp.cache.enabled=false
```

### Production Environment

**File**: `conf/production.properties`
```properties
# Production-specific MCP settings
mcp.server.enabled=true
mcp.security.auth.required=true
mcp.security.cors.enabled=true
mcp.security.cors.origins=https://app.example.com
mcp.security.rate.limit.enabled=true
mcp.logging.requests.enabled=false
mcp.logging.responses.enabled=false
mcp.cache.enabled=true
mcp.request.timeout=15
```

### Testing Environment

**File**: `conf/testing.properties`
```properties
# Testing-specific MCP settings
mcp.server.enabled=true
mcp.security.auth.required=false
mcp.features.tools.enabled=true
mcp.features.resources.enabled=true
mcp.cache.enabled=false
mcp.logging.requests.enabled=true
mcp.request.timeout=60
```

## Configuration Validation

### Startup Validation

The MCP server validates configuration at startup:

```groovy
class McpConfigValidator {
    def validateConfiguration(Map config) {
        // Validate required parameters
        assert config['mcp.protocol.version'] != null
        
        // Validate numeric ranges
        assert config['mcp.request.timeout'] as Integer > 0
        assert config['mcp.request.timeout'] as Integer <= 300
        
        // Validate feature combinations
        if (!config['mcp.features.tools.enabled']) {
            assert !config['mcp.features.prompts.enabled']
        }
        
        // Validate security settings
        if (config['mcp.security.auth.required']) {
            assert config['mcp.security.auth.method'] != null
        }
    }
}
```

### Runtime Configuration Changes

Some configuration parameters can be changed at runtime:

```groovy
// Runtime configuration updates
def updateConfiguration(String key, String value) {
    ec.factory.confFacade.setConfigProperty(key, value)
    
    // Notify components of configuration change
    if (key.startsWith('mcp.cache.')) {
        refreshCacheConfiguration()
    } else if (key.startsWith('mcp.security.')) {
        refreshSecurityConfiguration()
    }
}
```

## Configuration Examples

### Example 1: High-Security Setup

```xml
<parameter name="mcp.security.auth.required" value="true"/>
<parameter name="mcp.security.auth.method" value="bearer"/>
<parameter name="mcp.security.cors.enabled" value="true"/>
<parameter name="mcp.security.cors.origins" value="https://trusted-domain.com"/>
<parameter name="mcp.security.rate.limit.enabled" value="true"/>
<parameter name="mcp.security.rate.limit.requests" value="50"/>
<parameter name="mcp.logging.requests.enabled" value="true"/>
<parameter name="mcp.logging.sanitize.sensitive" value="true"/>
```

### Example 2: High-Performance Setup

```xml
<parameter name="mcp.cache.enabled" value="true"/>
<parameter name="mcp.cache.tools.ttl" value="600"/>
<parameter name="mcp.cache.resources.ttl" value="1800"/>
<parameter name="mcp.http.pool.size" value="100"/>
<parameter name="mcp.max.concurrent.requests" value="200"/>
<parameter name="mcp.request.timeout" value="10"/>
<parameter name="mcp.logging.requests.enabled" value="false"/>
```

### Example 3: Development Setup

```xml
<parameter name="mcp.security.auth.required" value="false"/>
<parameter name="mcp.security.cors.enabled" value="true"/>
<parameter name="mcp.security.cors.origins" value="*"/>
<parameter name="mcp.logging.requests.enabled" value="true"/>
<parameter name="mcp.logging.responses.enabled" value="true"/>
<parameter name="mcp.cache.enabled" value="false"/>
<parameter name="mcp.features.tools.enabled" value="true"/>
<parameter name="mcp.features.resources.enabled" value="true"/>
```

## Troubleshooting Configuration

### Common Configuration Issues

1. **Component Not Loading**
   - Check `component.xml` syntax
   - Verify all required parameters are set
   - Check dependency order

2. **Authentication Failures**
   - Verify `mcp.security.auth.required` setting
   - Check authentication method configuration
   - Validate token expiry settings

3. **CORS Issues**
   - Check `mcp.security.cors.origins` configuration
   - Verify HTTP methods are allowed
   - Check header configuration

4. **Performance Issues**
   - Review cache configuration
   - Check connection pool settings
   - Verify timeout values

### Configuration Debugging

Enable configuration debugging:

```xml
<parameter name="mcp.debug.config.enabled" value="true"/>
<parameter name="mcp.debug.config.log.level" value="DEBUG"/>
```

This will log all configuration values at startup and when they change.

For more configuration options and advanced scenarios, refer to the Moqui framework documentation and the GrowERP configuration guides.
