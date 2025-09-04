# Troubleshooting Guide

Comprehensive troubleshooting guide for the GrowERP MCP Server, covering common issues, diagnostic techniques, and solutions.

## Quick Diagnosis

### Health Check

Always start with the health check endpoint to verify basic server functionality:

```bash
curl http://localhost:8080/rest/s1/mcp/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": 1693747200000,
  "version": "1.0.0"
}
```

### Component Status

Check if the MCP server component is loaded:

```bash
# Check Moqui logs for component loading
grep -i "Component growerp"  runtime/log/moqui.log

```

## Common Issues

### 1. Component Not Loading

#### Symptoms
- MCP endpoints return 404
- Component not listed in Moqui startup logs
- Health check endpoint not accessible

#### Causes & Solutions

**Missing Dependencies**
```bash
# Check if growerp component is loaded first
grep "Component growerp loaded" runtime/log/moqui.log

# If not found, check component dependencies in component.xml
```

**Invalid component.xml**
```xml
<!-- Check for XML syntax errors -->
<?xml version="1.0" encoding="UTF-8"?>
<moqui-component name="growerp-mcp-server" version="1.0.0"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/moqui-conf-3.xsd">
    <depends-on name="growerp"/>
</moqui-component>
```

**Groovy Compilation Errors**
```bash
# Check for compilation errors
grep -i "compilation" runtime/log/moqui.log
grep -i "groovy" runtime/log/moqui.log

# Common issues:
# - Static compilation conflicts
# - Missing imports
# - Type errors
```

**Solution Steps:**
1. Verify `component.xml` syntax
2. Check dependency order (`growerp` must load first)
3. Review Groovy class compilation errors
4. Restart Moqui after fixes

### 2. Authentication Failures

#### Symptoms
- 401 Unauthorized responses
- Authentication-related error messages
- Access denied to MCP endpoints

#### Diagnosis
```bash
# Check authentication configuration
grep "mcp.security.auth" runtime/conf/*.properties

# Test without authentication
curl -v http://localhost:8080/rest/s1/mcp/health

# Test with authentication
curl -v -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/rest/s1/mcp/mcp
```

#### Solutions

**Disable Authentication (Development)**
```xml
<!-- In component.xml -->
<parameter name="mcp.security.auth.required" value="false"/>
```

**Configure Authentication (Production)**
```xml
<!-- In component.xml -->
<parameter name="mcp.security.auth.required" value="true"/>
<parameter name="mcp.security.auth.method" value="bearer"/>
```

**Valid Token Example**
```bash
# Get a valid token (method depends on your auth setup)
TOKEN=$(curl -X POST http://localhost:8080/rest/auth/login \
  -d '{"username":"admin","password":"admin"}' | jq -r '.token')

# Use token in MCP requests
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/rest/s1/mcp/mcp
```

### 3. JSON-RPC Protocol Errors

#### Symptoms
- "Parse error" responses
- "Invalid Request" errors
- "Method not found" errors

#### Common JSON-RPC Issues

**Invalid JSON Format**
```bash
# BAD: Missing quotes around strings
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{jsonrpc: 2.0, method: tools/list, id: 1}'

# GOOD: Proper JSON format
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
```

**Missing Required Fields**
```json
// BAD: Missing required fields
{
  "method": "tools/list"
}

// GOOD: All required fields present
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 1
}
```

**Invalid Method Names**
```json
// BAD: Wrong method name
{
  "jsonrpc": "2.0",
  "method": "list_tools",
  "id": 1
}

// GOOD: Correct method name
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 1
}
```

#### Error Response Analysis

**Error Code Reference**
- `-32700`: Parse error (invalid JSON)
- `-32600`: Invalid Request (missing fields)
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error

**Parse Error Example**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32700,
    "message": "Parse error"
  },
  "id": null
}
```

### 4. Tool Execution Failures

#### Symptoms
- Tools return error responses
- Tool execution timeouts
- "Tool not found" errors

#### Diagnosis

**List Available Tools**
```bash
curl http://localhost:8080/rest/s1/mcp/tools
```

**Test Tool Execution**
```bash
# Test ping tool (should always work)
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "ping_system",
      "arguments": {}
    },
    "id": 1
  }'
```

#### Common Tool Issues

**Tool Not Registered**
```groovy
// Check if tool is properly registered
// In McpToolManagerSimple.groovy
private def registerBuiltInTools() {
    registerTool("your_tool_name", [
        description: "Tool description",
        inputSchema: [...],
        executor: this.&executeYourTool
    ])
}
```

**Invalid Arguments**
```bash
# Check tool schema
curl http://localhost:8080/rest/s1/mcp/tools

# Use correct arguments based on schema
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

**Database Connection Issues**
```groovy
// In tool executor, add error handling
private def executeGetCompanies(Map arguments) {
    try {
        def companies = ec.entity.find("mantle.party.Organization")
            .selectField("partyId, organizationName")
            .limit(limit as Integer)
            .list()
        // ... rest of implementation
    } catch (Exception e) {
        ec.logger.error("Database error in get_companies", e)
        throw new RuntimeException("Database connection failed: ${e.message}")
    }
}
```

### 5. Resource Access Issues

#### Symptoms
- "Resource not found" errors
- Empty resource content
- Resource access denied

#### Diagnosis

**List Available Resources**
```bash
curl http://localhost:8080/rest/s1/mcp/resources
```

**Test Resource Reading**
```bash
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/read",
    "params": {
      "uri": "growerp://system/status"
    },
    "id": 1
  }'
```

#### Solutions

**Resource URI Format**
```bash
# GOOD: Valid resource URIs
growerp://entities/company
growerp://system/status
growerp://data/reports

# BAD: Invalid URIs
company
system/status
/entities/company
```

**Resource Registration Check**
```groovy
// In McpResourceManagerSimple.groovy
private def registerBuiltInResources() {
    registerResource("growerp://your/resource", [
        name: "Resource Name",
        description: "Resource description",
        mimeType: "application/json",
        generator: this.&generateYourResource
    ])
}
```

### 6. CORS Issues

#### Symptoms
- Browser CORS errors
- Cross-origin request failures
- OPTIONS preflight failures

#### Diagnosis
```bash
# Test CORS headers
curl -v -X OPTIONS http://localhost:8080/rest/s1/mcp/mcp \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

#### Solutions

**Enable CORS**
```xml
<!-- In component.xml -->
<parameter name="mcp.security.cors.enabled" value="true"/>
<parameter name="mcp.security.cors.origins" value="*"/>
```

**Specific Origins (Production)**
```xml
<parameter name="mcp.security.cors.origins" value="https://app.example.com,https://admin.example.com"/>
```

### 7. Performance Issues

#### Symptoms
- Slow response times
- Request timeouts
- High memory usage

#### Diagnosis

**Check Response Times**
```bash
# Time requests
time curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
```

**Monitor Memory Usage**
```bash
# Check Java process memory
ps aux | grep java
jstat -gc <java_pid>
```

**Database Performance**
```sql
-- Check slow queries
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Slow_queries';
```

#### Solutions

**Enable Caching**
```xml
<parameter name="mcp.cache.enabled" value="true"/>
<parameter name="mcp.cache.tools.ttl" value="300"/>
<parameter name="mcp.cache.resources.ttl" value="300"/>
```

**Database Optimization**
```xml
<!-- Increase connection pool -->
<parameter name="entity_ds_db_conf.connection_properties.maxActive" value="50"/>
<parameter name="entity_ds_db_conf.connection_properties.maxIdle" value="10"/>
```

**Request Timeout Configuration**
```xml
<parameter name="mcp.request.timeout" value="30"/>
```

## Diagnostic Techniques

### 1. Log Analysis

**Enable Debug Logging**
```xml
<!-- In MoquiConf.xml -->
<Logger name="growerp.mcp" level="DEBUG" additivity="false">
    <AppenderRef ref="stdout"/>
    <AppenderRef ref="file"/>
</Logger>
```

**Key Log Files**
- `runtime/log/moqui.log`: Main application log
- `runtime/log/error.log`: Error-specific log
- `runtime/log/mcp-server.log`: MCP-specific log (if configured)

**Common Log Patterns**
```bash
# Component loading issues
grep -i "component.*growerp-mcp-server" runtime/log/moqui.log

# Service execution errors
grep -i "service.*mcp" runtime/log/moqui.log

# Groovy compilation errors
grep -i "groovy.*error" runtime/log/moqui.log

# Database connection issues
grep -i "database.*error" runtime/log/moqui.log
```

### 2. Network Debugging

**Test Connectivity**
```bash
# Basic connectivity
telnet localhost 8080

# HTTP response headers
curl -I http://localhost:8080/rest/s1/mcp/health

# Detailed request/response
curl -v -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
```

**Using httpie for Better Formatting**
```bash
# Install httpie
pip install httpie

# Make formatted requests
http POST localhost:8080/rest/s1/mcp/mcp \
  jsonrpc=2.0 method=tools/list id:=1

# Pretty print responses
http POST localhost:8080/rest/s1/mcp/mcp \
  jsonrpc=2.0 method=tools/list id:=1 | jq .
```

### 3. Database Debugging

**Check Entity Definitions**
```bash
# List entities
grep -r "entity.*name" runtime/component/growerp/entity/

# Check specific entity
grep -A 20 "entity.*Organization" runtime/component/growerp/entity/
```

**Test Database Queries**
```sql
-- Test query directly in database
SELECT partyId, organizationName 
FROM Party p 
JOIN Organization o ON p.partyId = o.partyId 
LIMIT 10;
```

**Entity Engine Debugging**
```groovy
// Add debug logging to tool executors
ec.logger.debug("Executing query: ${queryBuilder.toString()}")
def results = queryBuilder.list()
ec.logger.debug("Query returned ${results.size()} results")
```

### 4. Configuration Debugging

**Check Configuration Values**
```bash
# List all MCP-related configuration
grep -r "mcp\." runtime/conf/

# Check runtime configuration
grep -i "mcp" runtime/log/moqui.log | grep -i "config"
```

**Runtime Configuration Inspection**
```groovy
// In Groovy code, check configuration values
def authRequired = ec.factory.confFacade.getConfigProperty("mcp.security.auth.required", "false")
ec.logger.info("Auth required: $authRequired")
```

## Error Code Reference

### JSON-RPC Error Codes

| Code | Name | Description | Common Causes |
|------|------|-------------|---------------|
| -32700 | Parse error | Invalid JSON received | Malformed JSON syntax |
| -32600 | Invalid Request | JSON not valid Request object | Missing required fields |
| -32601 | Method not found | Method does not exist | Typo in method name |
| -32602 | Invalid params | Invalid method parameters | Wrong parameter types/values |
| -32603 | Internal error | Internal JSON-RPC error | Server-side exceptions |

### HTTP Status Codes

| Code | Status | Description | Common Causes |
|------|--------|-------------|---------------|
| 200 | OK | Successful request | Normal operation |
| 400 | Bad Request | Invalid request format | Malformed JSON |
| 401 | Unauthorized | Authentication required | Missing/invalid token |
| 404 | Not Found | Endpoint not found | Component not loaded |
| 500 | Internal Server Error | Server error | Unhandled exceptions |

### Custom Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| MCP_001 | Component not initialized | Restart Moqui server |
| MCP_002 | Tool registration failed | Check tool definition |
| MCP_003 | Resource not accessible | Verify resource URI |
| MCP_004 | Database connection lost | Check database status |

## Performance Monitoring

### Key Metrics to Monitor

**Request Metrics**
- Requests per second
- Average response time
- Error rate
- Concurrent connections

**Resource Metrics**
- Memory usage
- CPU utilization
- Database connections
- Cache hit rate

### Monitoring Tools

**Basic Monitoring**
```bash
# Monitor request logs
tail -f runtime/log/moqui.log | grep "mcp"

# Check system resources
top -p $(pgrep -f moqui.war)

# Monitor network connections
netstat -an | grep :8080
```

**Advanced Monitoring**
```bash
# JVM monitoring
jstat -gc -t $(pgrep -f moqui.war) 1s

# Memory analysis
jmap -histo $(pgrep -f moqui.war)

# Thread analysis
jstack $(pgrep -f moqui.war)
```

## Common Solutions

### 1. Complete Reset

When all else fails, perform a complete reset:

```bash
# Stop Moqui
pkill -f moqui.war

# Clean and rebuild
cd /path/to/growerp/moqui
./gradlew clean build

# Reset database (CAUTION: This deletes all data)
./gradlew cleandb
java -jar moqui.war load types=seed,seed-initial,install no-run-es

# Restart Moqui
java -jar moqui.war no-run-es
```

### 2. Component Reinstallation

```bash
# Remove component
rm -rf runtime/component/growerp-mcp-server

# Reinstall from source
# (Copy component files back)

# Restart Moqui
pkill -f moqui.war
java -jar moqui.war no-run-es
```

### 3. Configuration Reset

```bash
# Backup current configuration
cp runtime/conf/MoquiConf.xml runtime/conf/MoquiConf.xml.backup

# Reset to defaults
# (Edit configuration files to remove custom MCP settings)

# Restart Moqui
pkill -f moqui.war
java -jar moqui.war no-run-es
```

## Getting Help

### Log Information to Collect

When reporting issues, include:

1. **Component Version**
```bash
grep "version" runtime/component/growerp-mcp-server/component.xml
```

2. **Moqui Version**
```bash
java -jar moqui.war --version
```

3. **Error Logs**
```bash
# Last 100 lines of main log
tail -100 runtime/log/moqui.log

# All MCP-related log entries
grep -i "mcp\|growerp-mcp-server" runtime/log/moqui.log
```

4. **Configuration**
```bash
# MCP-related configuration
grep -r "mcp\." runtime/conf/
```

5. **System Information**
```bash
java -version
uname -a
```

### Test Cases to Run

Provide results of these test cases:

```bash
# 1. Health check
curl http://localhost:8080/rest/s1/mcp/health

# 2. Component listing
curl http://localhost:8080/rest/s1/mcp/tools

# 3. Basic MCP request
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'

# 4. Tool execution
curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "ping_system", "arguments": {}}, "id": 2}'
```

### Community Resources

- **GrowERP Documentation**: https://www.growerp.com
- **Moqui Documentation**: https://www.moqui.org
- **Model Context Protocol**: https://modelcontextprotocol.io/
- **Issue Tracker**: (Provide URL for your issue tracker)

## Preventive Measures

### Regular Maintenance

1. **Monitor Logs Daily**
```bash
# Check for errors
grep -i error runtime/log/moqui.log | tail -20

# Check for warnings
grep -i warn runtime/log/moqui.log | tail -20
```

2. **Performance Monitoring**
```bash
# Weekly performance check
time curl -X POST http://localhost:8080/rest/s1/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
```

3. **Configuration Backup**
```bash
# Monthly configuration backup
cp -r runtime/conf runtime/conf.backup.$(date +%Y%m%d)
```

### Testing Checklist

Before deploying changes:

- [ ] Health check responds correctly
- [ ] All tools are listed
- [ ] Basic tool execution works
- [ ] Resource listing works
- [ ] Resource reading works
- [ ] Authentication works (if enabled)
- [ ] CORS headers present (if enabled)
- [ ] Performance is acceptable
- [ ] Logs show no errors

This troubleshooting guide should help you diagnose and resolve most issues with the GrowERP MCP Server. For issues not covered here, collect the diagnostic information mentioned and consult the community resources.
