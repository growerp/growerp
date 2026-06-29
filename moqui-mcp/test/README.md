# MCP Test Suite

This directory contains the Java-based test suite for the Moqui MCP (Model Context Protocol) implementation. The tests validate that the screen infrastructure works correctly through deterministic workflows.

## Overview

The test suite provides a Java equivalent to the `mcp.sh` script and includes comprehensive tests for:

1. **Screen Infrastructure Tests** - Basic MCP connectivity, screen discovery, rendering, and parameter handling
2. **PopCommerce Workflow Tests** - Complete business workflow: product lookup → order placement for John Doe

## Test Structure

```
test/
├── java/org/moqui/mcp/test/
│   ├── McpJavaClient.java          # Java MCP client (equivalent to mcp.sh)
│   ├── ScreenInfrastructureTest.java  # Screen infrastructure validation
│   ├── PopCommerceOrderTest.java   # PopCommerce order workflow test
│   └── McpTestSuite.java           # Main test runner
├── resources/
│   └── test-config.properties      # Test configuration
├── run-tests.sh                    # Test execution script
└── README.md                       # This file
```

## Prerequisites

1. **Moqui MCP Server Running**: The tests require the MCP server to be running at `http://localhost:8080/mcp`
2. **Java 17+**: Tests are written in Groovy/Java and require Java 17 or later
3. **Test Data**: JohnSales user should exist with appropriate permissions

## Running Tests

### Quick Start

```bash
# Run all tests
./test/run-tests.sh

# Run only infrastructure tests
./test/run-tests.sh infrastructure

# Run only workflow tests
./test/run-tests.sh workflow

# Show help
./test/run-tests.sh help
```

### Manual Execution

```bash
# Change to moqui-mcp-2 directory
cd moqui-mcp-2

# Set up classpath and run tests
java -cp "build/classes/java/main:build/resources/main:test/build/classes/java/test:test/resources:../moqui-framework/runtime/lib/*:../moqui-framework/framework/build/libs/*" \
     org.moqui.mcp.test.McpTestSuite
```

## Test Configuration

Tests are configured via `test/resources/test-config.properties`:

```properties
# MCP server connection
test.mcp.url=http://localhost:8080/mcp
test.user=john.sales
test.password=opencode

# Test data
test.customer.firstName=John
test.customer.lastName=Doe
test.product.color=blue
test.product.category=PopCommerce

# Test screens
test.screen.catalog=PopCommerce/Catalog/Product
test.screen.order=PopCommerce/Order/CreateOrder
test.screen.customer=PopCommerce/Customer/FindCustomer
```

## Test Details

### 1. Screen Infrastructure Tests

Validates basic MCP functionality:

- **Connectivity**: Can connect to MCP server and authenticate as JohnSales
- **Tool Discovery**: Can discover available screen tools
- **Screen Rendering**: Can render screens and get content back
- **Parameter Handling**: Can pass parameters to screens correctly
- **Error Handling**: Handles errors and edge cases gracefully

### 2. PopCommerce Workflow Tests

Tests complete business workflow:

1. **Catalog Access**: Find and access PopCommerce catalog screens
2. **Product Search**: Search for blue products in the catalog
3. **Customer Lookup**: Find John Doe customer record
4. **Order Creation**: Create an order for John Doe with a blue product
5. **Workflow Validation**: Validate the complete workflow succeeded

## Test Output

Tests provide detailed output with:

- ✅ Success indicators for passed steps
- ❌ Error indicators for failed steps with details
- 📊 Workflow summaries with timing information
- 📋 Comprehensive test reports

Example output:
```
🧪 MCP TEST SUITE
==================
Configuration:
  URL: http://localhost:8080/mcp
  User: john.sales
  Customer: John Doe
  Product Color: blue

==================================================
SCREEN INFRASTRUCTURE TESTS
==================================================
🔌 Testing Basic MCP Connectivity
==================================
🚀 Initializing MCP session...
✅ Session initialized: abc123
✅ Ping Server
✅ List Tools
✅ List Resources
```

## Deterministic Testing

The tests are designed to be deterministic:

- **Fixed Test Data**: Uses specific customer (John Doe) and product criteria (blue products)
- **Consistent Workflow**: Always follows the same sequence of operations
- **Repeatable Results**: Same inputs produce same outputs
- **State Validation**: Validates that each step completes successfully before proceeding

## Integration with Moqui Test Framework

The test structure follows Moqui's existing test patterns:

- Uses Groovy for test implementation (consistent with Moqui)
- Follows Moqui's package structure and naming conventions
- Integrates with Moqui's configuration system
- Uses Moqui's logging and error handling patterns

## Troubleshooting

### Common Issues

1. **MCP Server Not Running**
   ```
   ❌ MCP server not running at http://localhost:8080/mcp
   ```
   Solution: Start the server with `./gradlew run --daemon`

2. **Authentication Failures**
   ```
   ❌ Failed to initialize session
   ```
   Solution: Verify JohnSales user exists and credentials are correct

3. **Missing Screens**
   ```
   ❌ No catalog screens found
   ```
   Solution: Ensure PopCommerce component is installed and screens are available

4. **Classpath Issues**
   ```
   ClassNotFoundException
   ```
   Solution: Verify all required JARs are in the classpath

### Debug Mode

For detailed debugging, you can run individual test classes:

```bash
java -cp "..." org.moqui.mcp.test.McpJavaClient
java -cp "..." org.moqui.mcp.test.ScreenInfrastructureTest
java -cp "..." org.moqui.mcp.test.PopCommerceOrderTest
```

## Future Enhancements

Planned improvements to the test suite:

1. **More Workflows**: Additional business process tests
2. **Performance Tests**: Load testing and timing validation
3. **Negative Tests**: More comprehensive error scenario testing
4. **Integration Tests**: Cross-component workflow validation
5. **AI Comprehension Tests**: Once screen infrastructure is stable

## Contributing

When adding new tests:

1. Follow the existing structure and patterns
2. Use the `McpJavaClient` for all MCP communication
3. Record test steps using the workflow tracking system
4. Update configuration as needed
5. Add documentation for new test scenarios

## License

This test suite is in the public domain under CC0 1.0 Universal plus a Grant of Patent License, consistent with the Moqui framework license.