#!/bin/bash

###############################################################################
# GrowERP MCP Server Test Script
# 
# This script tests all available MCP server endpoints using test data
# from flutter/packages/growerp_core/lib/test_data.dart
#
# Usage: ./test_mcp_server.sh [BASE_URL]
# Default BASE_URL: http://localhost:8080
###############################################################################

# Note: set -e removed to allow better error handling
# set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${1:-http://localhost:8080}"
MCP_BASE="${BASE_URL}/rest/s1/mcp"
CLASSIFICATION_ID="AppSupport"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Email counter for unique emails (001-999)
EMAIL_COUNTER=0

# Temp file for responses
RESPONSE_FILE=$(mktemp)
trap "rm -f $RESPONSE_FILE" EXIT

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_test() {
    echo -e "\n${YELLOW}TEST: $1${NC}"
    ((TOTAL_TESTS++))
}

print_success() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((PASSED_TESTS++))
}

print_failure() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    echo -e "${RED}Response: $2${NC}"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

# Generate unique email by replacing XXX with sequential number
get_unique_email() {
    local template=$1
    ((EMAIL_COUNTER++))
    
    # Ensure counter stays within 001-999 range
    if [ $EMAIL_COUNTER -gt 999 ]; then
        EMAIL_COUNTER=1
    fi
    
    # Format counter as 3-digit number (001, 002, etc.)
    local formatted_counter=$(printf "%03d" $EMAIL_COUNTER)
    
    # Replace XXX or xxx with the formatted counter
    echo "$template" | sed -e "s/XXX/$formatted_counter/g" -e "s/xxx/$formatted_counter/g"
}

# Make HTTP request and save response
http_request() {
    local method=$1
    local url=$2
    local data=$3
    local headers=$4
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "$url" \
            -H "Content-Type: application/json" \
            ${headers:+-H "$headers"} \
            -d "$data" > "$RESPONSE_FILE" 2>&1
    else
        curl -s -X "$method" "$url" \
            ${headers:+-H "$headers"} > "$RESPONSE_FILE" 2>&1
    fi
    
    local curl_exit=$?
    if [ $curl_exit -ne 0 ]; then
        echo "{\"error\": \"curl failed with exit code $curl_exit\"}" > "$RESPONSE_FILE"
    fi
    
    cat "$RESPONSE_FILE"
}

# Check if JSON response contains expected field
check_response() {
    local expected_field=$1
    local response=$(cat "$RESPONSE_FILE")
    
    if echo "$response" | jq -e "$expected_field" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

###############################################################################
# Test Data (from test_data.dart)
###############################################################################

# Company test data template (XXX will be replaced with unique number)
COMPANY_DATA_TEMPLATE='{
  "name": "Test Main Company",
  "role": "Company",
  "currency": {"currencyId": "EUR", "description": "Euro"},
  "email": "testXXX@example.com",
  "telephoneNr": "555555555555",
  "address": {
    "address1": "mountain Ally 223",
    "address2": "suite 23",
    "postalCode": "90210",
    "city": "Los Angeles",
    "province": "California",
    "country": "United States"
  }
}'

# User test data template (XXX will be replaced with unique number)
USER_DATA_TEMPLATE='{
  "firstName": "John",
  "lastName": "Doe",
  "email": "testXXX@example.com",
  "username": "testuser",
  "userGroup": "Admin",
  "role": "Customer"
}'

# Product test data (no email needed)
PRODUCT_DATA='{
  "productName": "Test Product 1 - Shippable",
  "price": "23.99",
  "listPrice": "27.99",
  "description": "This is a test product",
  "productTypeId": "ProductTypeShippableGood",
  "useWarehouse": true,
  "assetClassId": "AsClsInventoryFin"
}'

# Supplier company data template (XXX will be replaced with unique number)
SUPPLIER_DATA_TEMPLATE='{
  "name": "Test Supplier Company 1",
  "role": "Supplier",
  "email": "supplierXXX@example.org",
  "telephoneNr": "99999999999999",
  "url": "https://supplier.example.org"
}'

# Customer company data template (XXX will be replaced with unique number)
CUSTOMER_DATA_TEMPLATE='{
  "name": "Test Customer Company 1",
  "role": "Customer",
  "email": "customerXXX@example.org",
  "telephoneNr": "111111111111"
}'

###############################################################################
# Authentication
###############################################################################

authenticate() {
    print_header "AUTHENTICATION"
    
    print_test "Login and get API key"
    
    local login_response
    login_response=$(http_request POST "${MCP_BASE}/auth/login" '{
        "username": "test@example.com",
        "password": "qqqqqq9!",
        "classificationId": "'"$CLASSIFICATION_ID"'"
    }')
    
    if check_response '.loginResponse.result.apiKey'; then
        API_KEY=$(echo "$login_response" | jq -r '.loginResponse.result.apiKey')
        print_success "Authentication successful. API Key obtained."
        print_info "API Key: ${API_KEY:0:20}..."
    else
        print_failure "Authentication failed" "$login_response"
        exit 1
    fi
}

###############################################################################
# Basic Endpoint Tests
###############################################################################

test_health_check() {
    print_header "HEALTH CHECK TESTS"
    
    print_test "GET /health"
    local response=$(http_request GET "${MCP_BASE}/health")
    
    if check_response '.status'; then
        print_success "Health check endpoint working"
        print_info "Status: $(echo "$response" | jq -r '.status')"
    else
        print_failure "Health check failed" "$response"
    fi
}

test_tools_list() {
    print_header "TOOLS ENDPOINT TESTS"
    
    print_test "GET /tools - List all available tools"
    local response=$(http_request GET "${MCP_BASE}/tools")
    
    if check_response '.tools'; then
        local tool_count=$(echo "$response" | jq '.tools | length')
        print_success "Tools list retrieved: $tool_count tools available"
        print_info "Sample tools: $(echo "$response" | jq -r '.tools[0:3][].name' | tr '\n' ', ' | sed 's/,$//')"
    else
        print_failure "Tools list failed" "$response"
    fi
}

test_resources_list() {
    print_header "RESOURCES ENDPOINT TESTS"
    
    print_test "GET /resources - List all available resources"
    local response=$(http_request GET "${MCP_BASE}/resources")
    
    if check_response '.resources'; then
        local resource_count=$(echo "$response" | jq '.resources | length')
        print_success "Resources list retrieved: $resource_count resources available"
        print_info "Sample resources: $(echo "$response" | jq -r '.resources[0:3][].uri' | tr '\n' ', ' | sed 's/,$//')"
    else
        print_failure "Resources list failed" "$response"
    fi
}

###############################################################################
# MCP Protocol Tests
###############################################################################

test_mcp_initialize() {
    print_header "MCP PROTOCOL - INITIALIZE"
    
    print_test "Initialize MCP connection"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {
                "name": "bash-test-client",
                "version": "1.0.0"
            }
        },
        "id": 1
    }' "api_key: $API_KEY")
    
    if check_response '.result.serverInfo'; then
        print_success "MCP initialization successful"
        print_info "Server: $(echo "$response" | jq -r '.result.serverInfo.name') v$(echo "$response" | jq -r '.result.serverInfo.version')"
    else
        print_failure "MCP initialization failed" "$response"
    fi
}

test_mcp_tools_list() {
    print_header "MCP PROTOCOL - TOOLS/LIST"
    
    print_test "List tools via MCP protocol"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/list",
        "id": 2
    }' "api_key: $API_KEY")
    
    if check_response '.result.tools'; then
        local tool_count=$(echo "$response" | jq '.result.tools | length')
        print_success "MCP tools/list successful: $tool_count tools"
    else
        print_failure "MCP tools/list failed" "$response"
    fi
}

test_mcp_resources_list() {
    print_header "MCP PROTOCOL - RESOURCES/LIST"
    
    print_test "List resources via MCP protocol"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "resources/list",
        "id": 3
    }' "api_key: $API_KEY")
    
    if check_response '.result.resources'; then
        local resource_count=$(echo "$response" | jq '.result.resources | length')
        print_success "MCP resources/list successful: $resource_count resources"
    else
        print_failure "MCP resources/list failed" "$response"
    fi
}

###############################################################################
# System Management Tools
###############################################################################

test_ping_system() {
    print_header "SYSTEM MANAGEMENT - PING"
    
    print_test "Ping system health"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "ping_system",
            "arguments": {}
        },
        "id": 10
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Ping system successful"
        print_info "Result: $(echo "$response" | jq -r '.result.text // .result')"
    else
        print_failure "Ping system failed" "$response"
    fi
}

test_get_entity_info() {
    print_header "SYSTEM MANAGEMENT - ENTITY INFO"
    
    print_test "Get entity information for 'Party'"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_entity_info",
            "arguments": {
                "entityName": "mantle.party.Party"
            }
        },
        "id": 11
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get entity info successful"
    else
        print_failure "Get entity info failed" "$response"
    fi
}

test_get_service_info() {
    print_header "SYSTEM MANAGEMENT - SERVICE INFO"
    
    print_test "Get service information"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_service_info",
            "arguments": {
                "serviceName": "growerp.100.GeneralServices100.get#Companies"
            }
        },
        "id": 12
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get service info successful"
    else
        print_failure "Get service info failed" "$response"
    fi
}

###############################################################################
# Company Management Tools
###############################################################################

test_get_companies() {
    print_header "COMPANY MANAGEMENT - GET"
    
    print_test "Get companies (limit 5)"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_companies",
            "arguments": {
                "limit": 5
            }
        },
        "id": 20
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get companies successful"
        print_info "Result: $(echo "$response" | jq -r '.result.text // "Companies retrieved"')"
    else
        print_failure "Get companies failed" "$response"
    fi
}

test_create_company() {
    print_header "COMPANY MANAGEMENT - CREATE"
    
    print_test "Create new company"
    
    # Generate unique company data with unique email
    local COMPANY_DATA=$(get_unique_email "$COMPANY_DATA_TEMPLATE")
    
    # Build JSON payload using jq to ensure proper JSON formatting with nested company object
    local payload=$(jq -n \
        --argjson companyData "$COMPANY_DATA" \
        '{
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": "create_company",
                "arguments": {
                    "company": $companyData
                }
            },
            "id": 21
        }')
    
    local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
    
    if check_response '.result'; then
        CREATED_COMPANY_ID=$(echo "$response" | jq -r '.result.data.company.partyId // .result.data.partyId // .result.partyId // ""')
        print_success "Create company successful"
        print_info "Company ID: $CREATED_COMPANY_ID"
        print_info "Email used: $(echo "$COMPANY_DATA" | jq -r '.email')"
    else
        print_failure "Create company failed" "$response"
    fi
}

test_update_company() {
    print_header "COMPANY MANAGEMENT - UPDATE"
    
    if [ -z "$CREATED_COMPANY_ID" ]; then
        print_info "Skipping update test - no company ID available"
        return
    fi
    
    print_test "Update company"
    
    # Build JSON payload using jq to ensure proper JSON formatting
    local payload=$(jq -n \
        --arg partyId "$CREATED_COMPANY_ID" \
        '{
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": "update_company",
                "arguments": {
                    "partyId": $partyId,
                    "companyName": "Updated Company Name",
                    "description": "Updated description"
                }
            },
            "id": 22
        }')
    
    local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Update company successful"
    else
        print_failure "Update company failed" "$response"
    fi
}

###############################################################################
# User Management Tools
###############################################################################

test_get_users() {
    print_header "USER MANAGEMENT - GET"
    
    print_test "Get users (limit 5)"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_users",
            "arguments": {
                "limit": 5
            }
        },
        "id": 30
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get users successful"
    else
        print_failure "Get users failed" "$response"
    fi
}

test_create_user() {
    print_header "USER MANAGEMENT - CREATE"
    
    print_test "Create new user"
    
    # Generate unique user data with unique email
    local USER_DATA=$(get_unique_email "$USER_DATA_TEMPLATE")
    
    # Build JSON payload using jq to ensure proper JSON formatting with nested user object
    local payload=$(jq -n \
        --argjson userData "$USER_DATA" \
        '{
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": "create_user",
                "arguments": {
                    "user": $userData
                }
            },
            "id": 31
        }')
    
    local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
    
    if check_response '.result'; then
        CREATED_USER_ID=$(echo "$response" | jq -r '.result.data.user.partyId // .result.data.userId // .result.userId // ""')
        print_success "Create user successful"
        print_info "User ID: $CREATED_USER_ID"
        print_info "Email used: $(echo "$USER_DATA" | jq -r '.email')"
    else
        print_failure "Create user failed" "$response"
    fi
}

###############################################################################
# Product Management Tools
###############################################################################

test_get_products() {
    print_header "PRODUCT MANAGEMENT - GET"
    
    print_test "Get products (limit 5)"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_products",
            "arguments": {
                "limit": 5
            }
        },
        "id": 40
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get products successful"
    else
        print_failure "Get products failed" "$response"
    fi
}

test_create_product() {
    print_header "PRODUCT MANAGEMENT - CREATE"
    
    print_test "Create new product"
    
    # Build JSON payload using jq to ensure proper JSON formatting with nested product object
    local payload=$(jq -n \
        --argjson productData "$PRODUCT_DATA" \
        '{
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": "create_product",
                "arguments": {
                    "product": $productData
                }
            },
            "id": 41
        }')
    
    local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
    
    if check_response '.result'; then
        CREATED_PRODUCT_ID=$(echo "$response" | jq -r '.result.data.product.productId // .result.data.productId // .result.productId // ""')
        print_success "Create product successful"
        print_info "Product ID: $CREATED_PRODUCT_ID"
    else
        print_failure "Create product failed" "$response"
    fi
}

###############################################################################
# Order Management Tools
###############################################################################

test_get_orders() {
    print_header "ORDER MANAGEMENT - GET"
    
    print_test "Get orders"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_orders",
            "arguments": {
                "limit": 5
            }
        },
        "id": 50
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get orders successful"
    else
        print_failure "Get orders failed" "$response"
    fi
}

test_create_sales_order() {
    print_header "ORDER MANAGEMENT - CREATE SALES ORDER"
    
    # Check if we have required IDs from previous tests
    if [ -z "$CREATED_COMPANY_ID" ]; then
        print_info "No company ID available - creating a customer company first"
        # Create a customer company for the order
        local CUSTOMER_DATA=$(get_unique_email "$CUSTOMER_DATA_TEMPLATE")
        local customer_payload=$(jq -n \
            --argjson companyData "$CUSTOMER_DATA" \
            '{
                "jsonrpc": "2.0",
                "method": "tools/call",
                "params": {
                    "name": "create_company",
                    "arguments": {
                        "company": $companyData
                    }
                },
                "id": 50
            }')
        
        local customer_response=$(http_request POST "${MCP_BASE}/protocol" "$customer_payload" "api_key: $API_KEY")
        CREATED_COMPANY_ID=$(echo "$customer_response" | jq -r '.result.data.company.partyId // .result.data.partyId // .result.partyId // ""')
        
        if [ -n "$CREATED_COMPANY_ID" ]; then
            print_info "Customer company created: $CREATED_COMPANY_ID"
        else
            print_failure "Failed to create customer company" "$customer_response"
            return
        fi
    fi
    
    if [ -z "$CREATED_PRODUCT_ID" ]; then
        print_info "No product ID available - creating a product first"
        # Create a product for the order
        local product_payload=$(jq -n \
            --argjson productData "$PRODUCT_DATA" \
            '{
                "jsonrpc": "2.0",
                "method": "tools/call",
                "params": {
                    "name": "create_product",
                    "arguments": {
                        "product": $productData
                    }
                },
                "id": 50
            }')
        
        local product_response=$(http_request POST "${MCP_BASE}/protocol" "$product_payload" "api_key: $API_KEY")
        CREATED_PRODUCT_ID=$(echo "$product_response" | jq -r '.result.data.product.productId // .result.data.productId // .result.productId // ""')
        
        if [ -n "$CREATED_PRODUCT_ID" ]; then
            print_info "Product created: $CREATED_PRODUCT_ID"
        else
            print_failure "Failed to create product" "$product_response"
            return
        fi
    fi
    
    print_test "Create sales order using company ID: $CREATED_COMPANY_ID and product ID: $CREATED_PRODUCT_ID"
    
    # Build the order with dynamic IDs
    local payload=$(jq -n \
        --arg companyId "$CREATED_COMPANY_ID" \
        --arg productId "$CREATED_PRODUCT_ID" \
        '{
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": "create_sales_order",
                "arguments": {
                    "finDoc": {
                        "docType": "order",
                        "sales": true,
                        "otherCompany": {
                            "partyId": $companyId
                        },
                        "items": [
                            {
                                "productId": $productId,
                                "quantity": 2,
                                "price": 23.99
                            }
                        ]
                    }
                }
            },
            "id": 51
        }')
    
    local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
    
    if check_response '.result'; then
        CREATED_ORDER_ID=$(echo "$response" | jq -r '.result.data.finDoc.orderId // .result.data.orderId // .result.orderId // ""')
        print_success "Create sales order successful"
        print_info "Order ID: $CREATED_ORDER_ID"
        print_info "Customer: $CREATED_COMPANY_ID"
        print_info "Product: $CREATED_PRODUCT_ID"
    else
        print_failure "Create sales order failed" "$response"
    fi
}

###############################################################################
# Financial Management Tools
###############################################################################

test_get_balance_summary() {
    print_header "FINANCIAL MANAGEMENT - BALANCE SUMMARY"
    
    print_test "Get balance summary for period 2024-Q1"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_balance_summary",
            "arguments": {
                "periodName": "2024-Q1"
            }
        },
        "id": 60
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get balance summary successful"
    else
        print_failure "Get balance summary failed" "$response"
    fi
}

###############################################################################
# Category Management Tools
###############################################################################

test_get_categories() {
    print_header "CATEGORY MANAGEMENT - GET"
    
    print_test "Get categories"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "get_categories",
            "arguments": {
                "limit": 5
            }
        },
        "id": 70
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        print_success "Get categories successful"
    else
        print_failure "Get categories failed" "$response"
    fi
}

test_create_category() {
    print_header "CATEGORY MANAGEMENT - CREATE"
    
    print_test "Create new category"
    local response=$(http_request POST "${MCP_BASE}/protocol" '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "create_category",
            "arguments": {
                "category": {
                    "categoryName": "Test Category 1",
                    "description": "Test category description"
                }
            }
        },
        "id": 71
    }' "api_key: $API_KEY")
    
    if check_response '.result'; then
        CREATED_CATEGORY_ID=$(echo "$response" | jq -r '.result.data.category.categoryId // .result.data.categoryId // .result.categoryId // ""')
        print_success "Create category successful"
        print_info "Category ID: $CREATED_CATEGORY_ID"
    else
        print_failure "Create category failed" "$response"
    fi
}

###############################################################################
# Main Test Execution
###############################################################################

main() {
    print_header "GROWERP MCP SERVER TEST SUITE"
    print_info "Base URL: $BASE_URL"
    print_info "MCP Endpoint: $MCP_BASE"
    print_info "Classification ID: $CLASSIFICATION_ID"
    
    # Authenticate first
    authenticate
    
    # Basic endpoint tests
    test_health_check
    test_tools_list
    test_resources_list
    
    # MCP protocol tests
    test_mcp_initialize
    test_mcp_tools_list
    test_mcp_resources_list
    
    # System management tests
    test_ping_system
    test_get_entity_info
    test_get_service_info
    
    # Company management tests
    test_get_companies
    test_create_company
    test_update_company
    
    # User management tests
    test_get_users
    test_create_user
    
    # Product management tests
    test_get_products
    test_create_product
    
    # Order management tests
    test_get_orders
    test_create_sales_order
    
    # Financial management tests
    test_get_balance_summary
    
    # Category management tests
    test_get_categories
    test_create_category
    
    # Print summary
    print_header "TEST SUMMARY"
    echo -e "${BLUE}Total Tests: ${TOTAL_TESTS}${NC}"
    echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but not installed. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed. Aborting."; exit 1; }

# Run main
main
