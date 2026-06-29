#!/bin/bash

# MCP Test Runner Script
# Runs Java MCP tests with proper classpath and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOQUI_MCP_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🧪 MCP Test Runner${NC}"
echo "===================="

# Check if Moqui MCP server is running
echo -e "${BLUE}🔍 Checking MCP server status...${NC}"
if ! curl -s http://localhost:8080/mcp > /dev/null 2>&1; then
    echo -e "${RED}❌ MCP server not running at http://localhost:8080/mcp${NC}"
    echo "Please start the Moqui MCP server first:"
    echo "  cd $MOQUI_MCP_DIR && ./gradlew run --daemon"
    exit 1
fi

echo -e "${GREEN}✅ MCP server is running${NC}"

# Set up Java classpath
echo -e "${BLUE}📦 Setting up classpath...${NC}"

# Add Moqui framework classes
CLASSPATH="$MOQUI_MCP_DIR/build/classes/java/main"
CLASSPATH="$CLASSPATH:$MOQUI_MCP_DIR/build/resources/main"

# Add test classes
CLASSPATH="$CLASSPATH:$MOQUI_MCP_DIR/build/classes/groovy/test"
CLASSPATH="$CLASSPATH:$MOQUI_MCP_DIR/build/resources/test"
CLASSPATH="$CLASSPATH:$MOQUI_MCP_DIR/test/resources"

# Add Moqui framework runtime libraries
if [ -d "$MOQUI_MCP_DIR/../moqui-framework/runtime/lib" ]; then
    for jar in "$MOQUI_MCP_DIR/../moqui-framework/runtime/lib"/*.jar; do
        if [ -f "$jar" ]; then
            CLASSPATH="$CLASSPATH:$jar"
        fi
    done
fi

# Add Groovy libraries
if [ -d "$MOQUI_MCP_DIR/../moqui-framework/runtime/lib" ]; then
    for jar in "$MOQUI_MCP_DIR/../moqui-framework/runtime/lib"/groovy*.jar; do
        if [ -f "$jar" ]; then
            CLASSPATH="$CLASSPATH:$jar"
        fi
    done
fi

# Add framework build
if [ -d "$MOQUI_MCP_DIR/../moqui-framework/framework/build/libs" ]; then
    for jar in "$MOqui_MCP_DIR/../moqui-framework/framework/build/libs"/*.jar; do
        if [ -f "$jar" ]; then
            CLASSPATH="$CLASSPATH:$jar"
        fi
    done
fi

# Add component JAR if it exists
if [ -f "$MOQUI_MCP_DIR/lib/moqui-mcp-2-1.0.0.jar" ]; then
    CLASSPATH="$CLASSPATH:$MOQUI_MCP_DIR/lib/moqui-mcp-2-1.0.0.jar"
fi

echo "Classpath: $CLASSPATH"

# Change to Moqui MCP directory
cd "$MOQUI_MCP_DIR"

# Determine which test to run
TEST_TYPE="$1"

case "$TEST_TYPE" in
    "infrastructure"|"infra")
        echo -e "${BLUE}🏗️ Running infrastructure tests only...${NC}"
        TEST_CLASS="org.moqui.mcp.test.McpTestSuite"
        TEST_ARGS="infrastructure"
        ;;
    "workflow"|"popcommerce")
        echo -e "${BLUE}🛒 Running PopCommerce workflow tests only...${NC}"
        TEST_CLASS="org.moqui.mcp.test.McpTestSuite"
        TEST_ARGS="workflow"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [test_type]"
        echo ""
        echo "Test types:"
        echo "  infrastructure, infra  - Run screen infrastructure tests only"
        echo "  workflow, popcommerce - Run PopCommerce workflow tests only"
        echo "  (no argument)          - Run all tests"
        echo ""
        echo "Examples:"
        echo "  $0"
        echo "  $0 infrastructure"
        echo "  $0 workflow"
        exit 0
        ;;
    "")
        echo -e "${BLUE}🧪 Running all MCP tests...${NC}"
        TEST_CLASS="org.moqui.mcp.test.McpTestSuite"
        TEST_ARGS=""
        ;;
    *)
        echo -e "${RED}❌ Unknown test type: $TEST_TYPE${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

# Run the tests
echo -e "${BLUE}🚀 Executing tests...${NC}"
echo ""

# Set Java options
JAVA_OPTS="-Xmx1g -Xms512m"
JAVA_OPTS="$JAVA_OPTS -Dmoqui.runtime=$MOQUI_MCP_DIR/../runtime"
JAVA_OPTS="$JAVA_OPTS -Dmoqui.conf=MoquiConf.xml"

# Execute the test using Gradle (which handles Groovy classpath properly)
echo "Running tests via Gradle..."
if cd "$MOQUI_MCP_DIR/../../.." && ./gradlew :runtime:component:moqui-mcp-2:test; then
    echo ""
    echo -e "${GREEN}🎉 Tests completed successfully!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
fi