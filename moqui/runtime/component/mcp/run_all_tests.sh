#!/bin/bash

# MCP Component Test Runner Script
# This script runs all tests in the MCP component and provides a comprehensive report

echo "=========================================="
echo "MCP Component Test Runner"
echo "=========================================="
echo "Date: $(date)"
echo "Component: /home/hans/growerp/moqui/runtime/component/mcp"
echo ""

# Change to the MCP component directory
cd /home/hans/growerp/moqui/runtime/component/mcp


echo "Running tests..."
echo "----------------------------------------"

# Run the tests and capture output
TEST_OUTPUT=$(/home/hans/growerp/moqui/gradlew test --console=plain 2>&1)
TEST_EXIT_CODE=$?

echo "$TEST_OUTPUT"
echo ""

echo "=========================================="
echo "TEST RESULTS SUMMARY"
echo "=========================================="

# Parse test results from the output
PASSED_TESTS=$(echo "$TEST_OUTPUT" | grep -c "PASSED")
FAILED_TESTS=$(echo "$TEST_OUTPUT" | grep -c "FAILED")
SKIPPED_TESTS=$(echo "$TEST_OUTPUT" | grep -c "SKIPPED")

echo "Exit Code: $TEST_EXIT_CODE"
echo "Tests Passed: $PASSED_TESTS"
echo "Tests Failed: $FAILED_TESTS"
echo "Tests Skipped: $SKIPPED_TESTS"

# Extract test execution details
echo ""
echo "DETAILED TEST RESULTS:"
echo "----------------------------------------"

# List all test classes that were executed
echo "$TEST_OUTPUT" | grep "Running test:" | sed 's/.*Running test: //' | while read -r test_name; do
    echo "• $test_name"
done

echo ""
echo "TEST EXECUTION SUMMARY:"
echo "----------------------------------------"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ ALL TESTS PASSED"
    echo "Status: SUCCESS"
else
    echo "❌ SOME TESTS FAILED"
    echo "Status: FAILURE"

    echo ""
    echo "FAILED TESTS:"
    echo "----------------------------------------"
    echo "$TEST_OUTPUT" | grep -A 5 -B 5 "FAILED" | grep -v "^\s*$" | head -20
fi

echo ""
echo "=========================================="
echo "Test execution completed at: $(date)"
echo "=========================================="

exit $TEST_EXIT_CODE
