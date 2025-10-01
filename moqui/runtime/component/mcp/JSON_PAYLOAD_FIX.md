# JSON Payload Fix - October 1, 2025

## Problem
When running the test script, the backend reported:
```
Error parsing HTTP request body JSON: com.fasterxml.jackson.core.JsonParseException: 
Unrecognized token 'invalid': was expecting (JSON String, Number, Array, Object or 
token 'null', 'true' or 'false')
```

## Root Cause
The original script used bash string substitution to embed JSON data into JSON payloads:
```bash
# ❌ WRONG: Shell variable substitution in double-quoted strings
local response=$(http_request POST "${MCP_BASE}/protocol" "{
    \"jsonrpc\": \"2.0\",
    \"params\": {
        \"arguments\": $COMPANY_DATA    # Problem: Not properly escaped
    }
}")
```

This caused issues because:
1. Shell variable expansion doesn't properly escape JSON
2. Special characters in the JSON break the string
3. Nested quotes cause parsing errors

## Solution
Use `jq` to properly construct JSON payloads:
```bash
# ✅ CORRECT: Use jq to build JSON
local COMPANY_DATA=$(get_unique_email "$COMPANY_DATA_TEMPLATE")

local payload=$(jq -n \
    --argjson args "$COMPANY_DATA" \
    '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "create_company",
            "arguments": $args
        },
        "id": 21
    }')

local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
```

## Changes Made

### 1. test_create_company()
**Before:**
```bash
local response=$(http_request POST "${MCP_BASE}/protocol" "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
        \"name\": \"create_company\",
        \"arguments\": $COMPANY_DATA
    },
    \"id\": 21
}" "api_key: $API_KEY")
```

**After:**
```bash
local payload=$(jq -n \
    --argjson args "$COMPANY_DATA" \
    '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "create_company",
            "arguments": $args
        },
        "id": 21
    }')

local response=$(http_request POST "${MCP_BASE}/protocol" "$payload" "api_key: $API_KEY")
```

### 2. test_create_user()
Same pattern - use `jq -n --argjson` to build payload

### 3. test_create_product()
Same pattern - use `jq -n --argjson` to build payload

### 4. test_update_company()
Use `jq -n --arg` for string arguments:
```bash
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
```

## Benefits

### ✅ Proper JSON Encoding
- `jq` ensures all JSON is properly formatted
- No manual escaping needed
- Handles special characters correctly

### ✅ Type Safety
- `--argjson`: Pass JSON objects/arrays
- `--arg`: Pass strings (automatically quoted)
- `--argjson` validates JSON before using it

### ✅ Readable Code
- No escaped quotes mess
- Clear JSON structure
- Easy to debug

## Testing the Fix

### Test 1: Validate JSON Generation
```bash
# Generate unique email
COMPANY_DATA=$(get_unique_email "$COMPANY_DATA_TEMPLATE")

# Check if valid JSON
echo "$COMPANY_DATA" | jq . > /dev/null 2>&1 && echo "Valid" || echo "Invalid"
```

**Expected:** ✅ Valid

### Test 2: Validate MCP Payload
```bash
# Build payload
payload=$(jq -n \
    --argjson args "$COMPANY_DATA" \
    '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "create_company",
            "arguments": $args
        },
        "id": 21
    }')

# Validate
echo "$payload" | jq . > /dev/null 2>&1 && echo "Valid" || echo "Invalid"
```

**Expected:** ✅ Valid

### Test 3: Run Full Test Script
```bash
cd /home/hans/growerp/moqui/runtime/component/mcp
./test_mcp_server.sh
```

**Expected:** No JSON parsing errors

## jq Command Reference

### --argjson (for JSON objects/arrays)
```bash
jq -n --argjson myvar '{"key": "value"}' '{result: $myvar}'
# Output: {"result": {"key": "value"}}
```

### --arg (for strings)
```bash
jq -n --arg mystring "hello" '{result: $mystring}'
# Output: {"result": "hello"}
```

### -n (null input)
```bash
jq -n '{key: "value"}'
# Output: {"key": "value"}
# (constructs JSON without reading input)
```

## Common Patterns

### Pattern 1: Embed JSON Object
```bash
DATA='{"name": "John", "age": 30}'
payload=$(jq -n --argjson data "$DATA" '{
    "action": "create",
    "user": $data
}')
```

### Pattern 2: Embed String Variables
```bash
NAME="John"
AGE=30
payload=$(jq -n \
    --arg name "$NAME" \
    --arg age "$AGE" \
    '{
        "name": $name,
        "age": ($age | tonumber)
    }')
```

### Pattern 3: Mix Both
```bash
USER_DATA='{"email": "test@example.com"}'
USER_ID="12345"

payload=$(jq -n \
    --argjson data "$USER_DATA" \
    --arg id "$USER_ID" \
    '{
        "userId": $id,
        "userData": $data
    }')
```

## Prevention Tips

### ❌ Don't Do This
```bash
# Shell substitution in JSON strings
DATA="{\"key\": \"value\"}"
JSON="{\"data\": $DATA}"  # WRONG
```

### ✅ Do This Instead
```bash
# Use jq to construct JSON
DATA='{"key": "value"}'
JSON=$(jq -n --argjson data "$DATA" '{data: $data}')  # CORRECT
```

### ❌ Don't Do This
```bash
# Manual escaping nightmare
VAR="test"
JSON="{\"field\": \"$VAR\", \"nested\": {\"key\": \"value\"}}"  # WRONG
```

### ✅ Do This Instead
```bash
# Let jq handle escaping
VAR="test"
JSON=$(jq -n --arg field "$VAR" '{
    field: $field,
    nested: {key: "value"}
}')  # CORRECT
```

## Verification Checklist

After making changes:
- [ ] Run `bash -n test_mcp_server.sh` (syntax check)
- [ ] Test unique email generation produces valid JSON
- [ ] Test jq payload construction produces valid JSON
- [ ] Run full test script against backend
- [ ] Check for JSON parsing errors in backend logs
- [ ] Verify all test functions work correctly

## Summary

**Problem:** Shell string substitution created invalid JSON  
**Solution:** Use `jq` to properly construct JSON payloads  
**Result:** Clean, valid JSON with proper escaping  

All test functions now use `jq -n` with `--argjson` or `--arg` to build payloads, ensuring 100% valid JSON every time! 🎉
