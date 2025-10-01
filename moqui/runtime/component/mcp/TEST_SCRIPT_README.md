# MCP Server Test Script

A comprehensive bash test script for the GrowERP MCP (Model Context Protocol) Server. This script tests all available endpoints using test data from the Flutter test suite.

## Overview

The `test_mcp_server.sh` script provides automated testing for:
- Basic health check endpoints
- MCP protocol initialization
- System management tools
- Entity CRUD operations (Companies, Users, Products, Categories)
- Business workflows (Orders, Invoices, Financial reports)
- Resource and tool discovery

## Features

- ✅ **Comprehensive Coverage**: Tests 25+ MCP endpoints
- ✅ **Colorized Output**: Easy-to-read test results with color coding
- ✅ **Test Data**: Uses realistic test data from `flutter/packages/growerp_core/lib/test_data.dart`
- ✅ **Authentication**: Handles API key authentication automatically
- ✅ **Detailed Reporting**: Shows pass/fail counts and response details
- ✅ **Error Handling**: Graceful error handling with informative messages

## Prerequisites

### Required Tools
```bash
# Install jq (JSON processor)
sudo apt-get install jq  # Ubuntu/Debian
brew install jq          # macOS

# curl is usually pre-installed
curl --version
```

### Running Moqui Server
Make sure the Moqui server is running:
```bash
cd /home/hans/growerp/moqui
java -jar moqui.war no-run-es
```

## Usage

### Basic Usage
```bash
# Run tests against default localhost:8080
./test_mcp_server.sh

# Run tests against custom server
./test_mcp_server.sh http://your-server:8080
```

### Test Categories

The script tests the following categories:

1. **Health Check Tests**
   - GET /health endpoint

2. **Tools & Resources Tests**
   - GET /tools - List available tools
   - GET /resources - List available resources

3. **MCP Protocol Tests**
   - initialize - MCP connection setup
   - tools/list - List tools via JSON-RPC
   - resources/list - List resources via JSON-RPC

4. **System Management**
   - ping_system - Health check
   - get_entity_info - Entity schema information
   - get_service_info - Service metadata

5. **Company Management**
   - get_companies - Retrieve companies
   - create_company - Create new company
   - update_company - Update company data

6. **User Management**
   - get_users - Retrieve users
   - create_user - Create new user

7. **Product Management**
   - get_products - Retrieve products
   - create_product - Create new product

8. **Order Management**
   - get_orders - Retrieve orders
   - create_sales_order - Create sales order

9. **Financial Management**
   - get_balance_summary - Financial reports

10. **Category Management**
    - get_categories - Retrieve categories
    - create_category - Create new category

## Test Data

The script uses test data matching the Flutter test suite from `flutter/packages/growerp_core/lib/test_data.dart`:

### Unique Email Generation

**Important:** All email addresses are automatically made unique by replacing `XXX` or `xxx` placeholders with sequential numbers (001-999). This ensures:
- ✅ No duplicate email conflicts during testing
- ✅ Each test run creates entities with unique identifiers  
- ✅ Emails follow the pattern: `testXXX@example.com` → `test001@example.com`, `test002@example.com`, etc.

The email counter increments for each entity created and resets to 001 after reaching 999.

### Companies
- Main Company with address and payment info
- Supplier companies (unique emails: `supplierXXX@example.org`)
- Customer companies (unique emails: `customerXXX@example.org`)
- Lead companies

### Users
- Administrators
- Employees (unique emails: `testXXX@example.com`)
- Customers
- Suppliers

### Products
- Shippable goods
- Services
- Rental products
- Subscription products

### Orders & Invoices
- Purchase orders
- Sales orders
- Invoices
- Payments

## Authentication

The script uses the following test credentials:
```bash
Username: test@example.com
Password: qqqqqq9!
Classification ID: AppSupport
```

API key is automatically obtained during the authentication phase.

## Output Format

### Success Output
```
========================================
HEALTH CHECK TESTS
========================================

TEST: GET /health
✓ PASS: Health check endpoint working
ℹ INFO: Status: healthy
```

### Failure Output
```
TEST: Create company
✗ FAIL: Create company failed
Response: {"error": "Company name already exists"}
```

### Summary
```
========================================
TEST SUMMARY
========================================
Total Tests: 25
Passed: 23
Failed: 2

❌ Some tests failed
```

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Customization

### Modify Test Data
Edit the test data variables in the script:
```bash
COMPANY_DATA='{
  "name": "Your Company Name",
  "role": "Company",
  ...
}'
```

### Add New Tests
Add new test functions following the pattern:
```bash
test_your_feature() {
    print_header "YOUR FEATURE - DESCRIPTION"
    
    print_test "Test description"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "your_tool_name",
            "arguments": {...}
        },
        "id": 100
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Test passed"
    else
        print_failure "Test failed" "$response"
    fi
}
```

## Troubleshooting

### JSON Parsing Errors
If you see errors like "Error parsing HTTP request body JSON" or "Unrecognized token":
```bash
# This is usually caused by invalid JSON in the payload
# The script now uses jq to properly construct JSON
# See JSON_PAYLOAD_FIX.md for details

# Verify jq is installed and working
jq --version

# Test JSON generation manually
COMPANY_DATA='{"email": "test001@example.com"}'
jq -n --argjson args "$COMPANY_DATA" '{"arguments": $args}'
```

### Connection Refused
```bash
# Check if Moqui is running
curl http://localhost:8080/rest/s1/mcp/health

# Start Moqui if needed
cd /home/hans/growerp/moqui
java -jar moqui.war no-run-es
```

### Authentication Failed
```bash
# Verify credentials
curl -X POST "http://localhost:8080/rest/s1/mcp/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test@example.com",
    "password": "qqqqqq9!",
    "classificationId": "AppSupport"
  }'
```

### jq Not Found
```bash
# Install jq
sudo apt-get update && sudo apt-get install -y jq
```

### Permission Denied
```bash
# Make script executable
chmod +x test_mcp_server.sh
```

## Integration with CI/CD

### GitHub Actions
```yaml
- name: Run MCP Server Tests
  run: |
    cd moqui/runtime/component/mcp
    ./test_mcp_server.sh http://localhost:8080
```

### GitLab CI
```yaml
test_mcp_server:
  script:
    - cd moqui/runtime/component/mcp
    - ./test_mcp_server.sh http://localhost:8080
```

## Related Documentation

- [MCP Server README](../README.md)
- [API Reference](docs/api-reference.md)
- [Quick Start Guide](docs/quick-start.md)
- [Flutter Test Data](../../../flutter/packages/growerp_core/lib/test_data.dart)

## Example Output

```bash
$ ./test_mcp_server.sh

========================================
GROWERP MCP SERVER TEST SUITE
========================================
ℹ INFO: Base URL: http://localhost:8080
ℹ INFO: MCP Endpoint: http://localhost:8080/rest/s1/mcp
ℹ INFO: Classification ID: AppSupport

========================================
AUTHENTICATION
========================================

TEST: Login and get API key
✓ PASS: Authentication successful. API Key obtained.
ℹ INFO: API Key: c3f2e1d0b9a8756443...

========================================
HEALTH CHECK TESTS
========================================

TEST: GET /health
✓ PASS: Health check endpoint working
ℹ INFO: Status: healthy

========================================
TOOLS ENDPOINT TESTS
========================================

TEST: GET /tools - List all available tools
✓ PASS: Tools list retrieved: 25 tools available
ℹ INFO: Sample tools: ping_system, get_companies, create_company

...

========================================
TEST SUMMARY
========================================
Total Tests: 25
Passed: 25
Failed: 0

🎉 All tests passed!
```

## Contributing

To add new tests:

1. Add test data to the "Test Data" section
2. Create a new test function following the naming pattern `test_*`
3. Call the function in the `main()` function
4. Update this README with the new test description

## License

This test script is part of the GrowERP project and is released under CC0 1.0 Universal plus a Grant of Patent License.
