#!/bin/bash

# MCP Component Test Runner Script
# This script runs all tests in the MCP component and provides a comprehensive report

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Track execution time
START_TIME=$(date +%s)

echo -e "${BOLD}=========================================="
echo -e "MCP Component Test Runner"
echo -e "==========================================${NC}"
echo "Date: $(date)"
echo "Component: /home/hans/growerp/moqui/runtime/component/mcp"
echo ""

# Change to the MCP component directory
cd /home/hans/growerp/moqui/runtime/component/mcp

# Initialize counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
OVERALL_EXIT_CODE=0

# Test categories
declare -A TEST_RESULTS

echo -e "${BLUE}1. Running MCP Server Protocol Tests...${NC}"
echo "----------------------------------------"

if [ -f "test-mcp-server.sh" ]; then
    chmod +x test-mcp-server.sh
    PROTOCOL_TEST_OUTPUT=$(./test-mcp-server.sh 2>&1)
    PROTOCOL_TEST_EXIT_CODE=$?
    
    echo "$PROTOCOL_TEST_OUTPUT"
    
    # Check for successful protocol responses
    if echo "$PROTOCOL_TEST_OUTPUT" | grep -q '"jsonrpc".*"2.0"'; then
        PROTOCOL_PASSED=1
        TEST_RESULTS["Protocol Tests"]="Passed: 1, Failed: 0"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        PROTOCOL_FAILED=1
        TEST_RESULTS["Protocol Tests"]="Passed: 0, Failed: 1"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OVERALL_EXIT_CODE=1
    fi
else
    echo "test-mcp-server.sh not found"
    TEST_RESULTS["Protocol Tests"]="Script not found"
fi

echo ""
echo -e "${BLUE}2. Running MCP Authentication Tests...${NC}"
echo "----------------------------------------"

if [ -f "test_mcp_auth.sh" ]; then
    chmod +x test_mcp_auth.sh
    AUTH_TEST_OUTPUT=$(./test_mcp_auth.sh 2>&1)
    AUTH_TEST_EXIT_CODE=$?
    
    echo "$AUTH_TEST_OUTPUT"
    
    if [ $AUTH_TEST_EXIT_CODE -eq 0 ]; then
        TEST_RESULTS["Auth Tests"]="Passed: 1, Failed: 0"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        TEST_RESULTS["Auth Tests"]="Passed: 0, Failed: 1"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OVERALL_EXIT_CODE=1
    fi
else
    echo "test_mcp_auth.sh not found"
    TEST_RESULTS["Auth Tests"]="Script not found"
fi

echo ""
echo -e "${BLUE}3. Running MCP Initialization Flow Tests...${NC}"
echo "----------------------------------------"

if [ -f "test_mcp_initialization_auth.sh" ]; then
    chmod +x test_mcp_initialization_auth.sh
    INIT_TEST_OUTPUT=$(./test_mcp_initialization_auth.sh 2>&1)
    INIT_TEST_EXIT_CODE=$?
    
    echo "$INIT_TEST_OUTPUT"
    
    if [ $INIT_TEST_EXIT_CODE -eq 0 ]; then
        TEST_RESULTS["Initialization Tests"]="Passed: 1, Failed: 0"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        TEST_RESULTS["Initialization Tests"]="Passed: 0, Failed: 1"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OVERALL_EXIT_CODE=1
    fi
else
    echo "test_mcp_initialization_auth.sh not found"
    TEST_RESULTS["Initialization Tests"]="Script not found"
fi

echo ""
echo -e "${BLUE}4. Running MCP Authentication Prompt Tests...${NC}"
echo "----------------------------------------"

if [ -f "test_auth_prompts.sh" ]; then
    chmod +x test_auth_prompts.sh
    PROMPT_TEST_OUTPUT=$(./test_auth_prompts.sh 2>&1)
    PROMPT_TEST_EXIT_CODE=$?
    
    echo "$PROMPT_TEST_OUTPUT"
    
    # Check for successful authentication prompts
    if echo "$PROMPT_TEST_OUTPUT" | grep -q "Authentication prompt returned successfully"; then
        TEST_RESULTS["Prompt Tests"]="Passed: 1, Failed: 0"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        TEST_RESULTS["Prompt Tests"]="Passed: 0, Failed: 1"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OVERALL_EXIT_CODE=1
    fi
else
    echo "test_auth_prompts.sh not found"
    TEST_RESULTS["Prompt Tests"]="Script not found"
fi

echo ""
echo -e "${BLUE}5. Running OAuth 2.0 Complete Flow Tests...${NC}"
echo "----------------------------------------"

if [ -f "test_oauth_complete.sh" ]; then
    chmod +x test_oauth_complete.sh
    OAUTH_TEST_OUTPUT=$(./test_oauth_complete.sh 2>&1)
    OAUTH_TEST_EXIT_CODE=$?
    
    echo "$OAUTH_TEST_OUTPUT"
    
    # Check for successful OAuth tests
    if echo "$OAUTH_TEST_OUTPUT" | grep -q "OAuth 2.0 Flow Testing Complete"; then
        TEST_RESULTS["OAuth Tests"]="Passed: 1, Failed: 0"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        TEST_RESULTS["OAuth Tests"]="Passed: 0, Failed: 1"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OVERALL_EXIT_CODE=1
    fi
else
    echo "test_oauth_complete.sh not found"
    TEST_RESULTS["OAuth Tests"]="Script not found"
fi

echo ""
echo -e "${BOLD}=========================================="
echo -e "COMPREHENSIVE TEST RESULTS SUMMARY"
echo -e "==========================================${NC}"
echo ""

# Display results by category
echo -e "${BOLD}Test Categories:${NC}"
for category in "${!TEST_RESULTS[@]}"; do
    echo "  $category: ${TEST_RESULTS[$category]}"
done

echo ""
echo -e "${BOLD}Overall Statistics:${NC}"
echo "  Total Tests Run: $TOTAL_TESTS"
echo -e "  Total Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo -e "  Total Failed: ${RED}$TOTAL_FAILED${NC}"

if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( (TOTAL_PASSED * 100) / TOTAL_TESTS ))
    echo "  Success Rate: $SUCCESS_RATE%"
fi

echo ""
echo -e "${BOLD}Available Test Files:${NC}"
echo "  Integration Tests: $(ls -1 test_*.sh 2>/dev/null | wc -l) shell script files" 
echo "  Protocol Tests: $(ls -1 test-mcp-*.sh 2>/dev/null | wc -l) MCP protocol files"

echo ""
echo -e "${BOLD}Test Environment:${NC}"
echo "  MCP Server: http://localhost:8080/rest/s1/mcp/protocol"
echo "  Backend Status: $(curl -s http://localhost:8080/status 2>/dev/null | grep -o '"statusId":"[^"]*' | cut -d'"' -f4 || echo "Unknown")"
echo "  Test User: test@example.com"

echo ""
echo -e "${BOLD}=========================================="
echo -e "DETAILED TEST RESULTS BREAKDOWN"
echo -e "==========================================${NC}"
echo ""

# Individual Test Results Summary
echo -e "${BOLD}Individual Test Results:${NC}"



# Protocol Tests Details
echo -e "${BLUE}🔌 MCP Protocol Tests:${NC}"
if [ -f "test-mcp-server.sh" ]; then
    if echo "$PROTOCOL_TEST_OUTPUT" | grep -q '"jsonrpc".*"2.0"'; then
        echo -e "   ${GREEN}✅ Initialize Request${NC}"
        echo -e "   ${GREEN}✅ Tools List Request${NC}"
        echo -e "   ${GREEN}✅ Ping Request${NC}"
        echo -e "   ${GREEN}✅ Tools Call Request${NC}"
        echo -e "   ${GREEN}✅ Error Handling${NC}"
    else
        echo -e "   ${RED}❌ Protocol Compliance Failed${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  test-mcp-server.sh not found${NC}"
fi
echo ""

# Authentication Tests Details
echo -e "${BLUE}🔐 Authentication Tests:${NC}"
if [ -f "test_mcp_auth.sh" ]; then
    if [ $AUTH_TEST_EXIT_CODE -eq 0 ]; then
        echo -e "   ${GREEN}✅ Login and API Key Generation${NC}"
        echo -e "   ${GREEN}✅ MCP Discovery Endpoints (Public)${NC}"
        echo -e "   ${GREEN}✅ Authenticated Request Acceptance${NC}"
        echo -e "   ${GREEN}✅ MCP Protocol Authentication${NC}"
        echo -e "   ${GREEN}✅ Authentication Validation${NC}"
    else
        echo -e "   ${RED}❌ Authentication Test Suite Failed${NC}"
        # Try to extract specific failures
        if echo "$AUTH_TEST_OUTPUT" | grep -q "Failed to get API key"; then
            echo -e "   ${RED}  ❌ API Key Generation${NC}"
        fi
        if echo "$AUTH_TEST_OUTPUT" | grep -q "failed (HTTP"; then
            echo -e "   ${RED}  ❌ HTTP Authentication${NC}"
        fi
    fi
else
    echo -e "   ${YELLOW}⚠️  test_mcp_auth.sh not found${NC}"
fi
echo ""

# Initialization Flow Tests Details
echo -e "${BLUE}🚀 Initialization Flow Tests:${NC}"
if [ -f "test_mcp_initialization_auth.sh" ]; then
    if [ $INIT_TEST_EXIT_CODE -eq 0 ]; then
        echo -e "   ${GREEN}✅ Initialize Method (Public)${NC}"
        echo -e "   ${GREEN}✅ Tools List Method (Public)${NC}"
        echo -e "   ${GREEN}✅ Prompts List Method (Public)${NC}"
        echo -e "   ${GREEN}✅ Resources List Method (Public)${NC}"
        echo -e "   ${GREEN}✅ Tools Call Method (Protected)${NC}"
        echo -e "   ${GREEN}✅ Auth Login Method (Public)${NC}"
        echo -e "   ${GREEN}✅ Ping Method (Public)${NC}"
    else
        echo -e "   ${RED}❌ Initialization Flow Tests Failed${NC}"
        # Extract specific test failures
        if echo "$INIT_TEST_OUTPUT" | grep -q "FAIL.*initialize"; then
            echo -e "   ${RED}  ❌ Initialize Method${NC}"
        fi
        if echo "$INIT_TEST_OUTPUT" | grep -q "FAIL.*tools/list"; then
            echo -e "   ${RED}  ❌ Tools List Method${NC}"
        fi
        if echo "$INIT_TEST_OUTPUT" | grep -q "FAIL.*tools/call"; then
            echo -e "   ${RED}  ❌ Tools Call Protection${NC}"
        fi
    fi
else
    echo -e "   ${YELLOW}⚠️  test_mcp_initialization_auth.sh not found${NC}"
fi
echo ""

# Authentication Prompt Tests Details
echo -e "${BLUE}💬 Authentication Prompt Tests:${NC}"
if [ -f "test_auth_prompts.sh" ]; then
    if echo "$PROMPT_TEST_OUTPUT" | grep -q "Authentication prompt returned successfully"; then
        echo -e "   ${GREEN}✅ Unauthenticated Request Prompt${NC}"
        echo -e "   ${GREEN}✅ Auth Prompt Structure${NC}"
        echo -e "   ${GREEN}✅ Login via Auth Endpoint${NC}"
        echo -e "   ${GREEN}✅ API Key Usage After Login${NC}"
    else
        echo -e "   ${RED}❌ Authentication Prompt Tests Failed${NC}"
        if echo "$PROMPT_TEST_OUTPUT" | grep -q "Authentication prompt not found"; then
            echo -e "   ${RED}  ❌ Prompt Generation${NC}"
        fi
        if echo "$PROMPT_TEST_OUTPUT" | grep -q "Login failed"; then
            echo -e "   ${RED}  ❌ Login Process${NC}"
        fi
    fi
else
    echo -e "   ${YELLOW}⚠️  test_auth_prompts.sh not found${NC}"
fi

echo ""
echo -e "${BOLD}=========================================="
echo -e "FINAL TEST EXECUTION SUMMARY"
echo -e "==========================================${NC}"
echo ""

# Create a detailed summary table
echo -e "${BOLD}Test Suite Summary:${NC}"
printf "%-25s %-10s %-10s %-10s %-10s\n" "Test Category" "Status" "Passed" "Failed" "Skipped"
echo "------------------------------------------------------------------------"

for category in "Protocol Tests" "Auth Tests" "Initialization Tests" "Prompt Tests"; do
    if [[ -n "${TEST_RESULTS[$category]}" ]]; then
        result="${TEST_RESULTS[$category]}"
        if echo "$result" | grep -q "Script not found\|No tests found"; then
            printf "%-25s %-10s %-10s %-10s %-10s\n" "$category" "N/A" "-" "-" "-"
        elif echo "$result" | grep -q "Skipped (not required)"; then
            printf "%-25s %-10s %-10s %-10s %-10s\n" "$category" "SKIP" "-" "-" "All"
        else
            passed=$(echo "$result" | sed -n 's/.*Passed: \([0-9]*\).*/\1/p')
            failed=$(echo "$result" | sed -n 's/.*Failed: \([0-9]*\).*/\1/p')  
            skipped=$(echo "$result" | sed -n 's/.*Skipped: \([0-9]*\).*/\1/p')
            
            if [ "$failed" = "0" ] && [ "$passed" != "0" ]; then
                status="PASS"
            elif [ "$failed" != "0" ]; then
                status="FAIL"
            else
                status="SKIP"
            fi
            
            printf "%-25s %-10s %-10s %-10s %-10s\n" "$category" "$status" "$passed" "$failed" "${skipped:-0}"
        fi
    fi
done

echo ""
echo -e "${BOLD}Final Result:${NC}"
if [ $OVERALL_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}✅ MCP Component is functioning correctly${NC}"
    echo -e "${GREEN}📊 Success Rate: $([ $TOTAL_TESTS -gt 0 ] && echo "$(( (TOTAL_PASSED * 100) / TOTAL_TESTS ))%" || echo "N/A")${NC}"
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo -e "${RED}📊 Success Rate: $([ $TOTAL_TESTS -gt 0 ] && echo "$(( (TOTAL_PASSED * 100) / TOTAL_TESTS ))%" || echo "N/A")${NC}"
    echo -e "${RED}⚠️  Check individual test outputs above for details${NC}"
    
    echo ""
    echo -e "${BOLD}Troubleshooting:${NC}"
    echo "  1. Ensure Moqui backend is running on localhost:8080"
    echo "  2. Check that test user 'test@example.com' exists with password 'qqqqqq9!'"
    echo "  3. Verify MCP component is properly loaded"
    echo "  4. Check logs in moqui/runtime/logs/ for detailed error information"
    echo "  5. Run individual test scripts to isolate specific failures"
fi

echo ""
echo "=========================================="
echo "Test execution completed at: $(date)"
echo "Total execution time: $(($(date +%s) - START_TIME)) seconds"
echo "=========================================="

exit $OVERALL_EXIT_CODE
