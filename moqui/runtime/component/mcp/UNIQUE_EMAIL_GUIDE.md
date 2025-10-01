# Unique Email Generation Guide

## Overview

The MCP test script automatically generates unique email addresses for all test entities to prevent duplicate email conflicts. This is accomplished by replacing `XXX` or `xxx` placeholders with sequential three-digit numbers (001-999).

## How It Works

### 1. Email Counter
```bash
EMAIL_COUNTER=0  # Initialized at script start
```

### 2. Generation Function
```bash
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
```

### 3. Usage in Test Data
```bash
# Template with XXX placeholder
COMPANY_DATA_TEMPLATE='{
  "name": "Test Main Company",
  "email": "testXXX@example.com",
  ...
}'

# Generate unique data
COMPANY_DATA=$(get_unique_email "$COMPANY_DATA_TEMPLATE")
# Result: {"email": "test001@example.com", ...}

# Next call increments counter
USER_DATA=$(get_unique_email "$USER_DATA_TEMPLATE")  
# Result: {"email": "test002@example.com", ...}
```

## Email Patterns

### Companies
- **Template:** `testXXX@example.com`
- **Examples:** `test001@example.com`, `test002@example.com`, `test003@example.com`

### Suppliers
- **Template:** `supplierXXX@example.org`
- **Examples:** `supplier001@example.org`, `supplier002@example.org`

### Customers
- **Template:** `customerXXX@example.org`
- **Examples:** `customer001@example.org`, `customer002@example.org`

### Users
- **Template:** `testXXX@example.com`
- **Examples:** `test001@example.com`, `test002@example.com`

## Counter Behavior

### Sequential Increment
```
First entity:   001
Second entity:  002
Third entity:   003
...
```

### Maximum Range
- **Range:** 001 to 999
- **Total unique emails per pattern:** 999
- **Wraparound:** After 999, counter resets to 001

### Multiple Test Runs
Each time you run the script:
1. Counter starts at 0
2. First email created uses 001
3. Counter increments for each new entity
4. Script can create up to 999 unique entities per run

## Benefits

### ✅ No Duplicate Conflicts
- Each entity gets a unique email address
- No database constraint violations
- Tests can run repeatedly without cleanup

### ✅ Predictable Pattern
- Easy to identify test data
- Sequential numbering for tracking
- Clear relationship between test order and email

### ✅ Automatic Management
- No manual email generation needed
- Counter managed automatically
- Wraparound prevents overflow

## Examples

### Creating Multiple Companies
```bash
# First company
COMPANY_DATA_1=$(get_unique_email "$COMPANY_DATA_TEMPLATE")
# Email: test001@example.com

# Second company  
COMPANY_DATA_2=$(get_unique_email "$COMPANY_DATA_TEMPLATE")
# Email: test002@example.com

# Third company
COMPANY_DATA_3=$(get_unique_email "$COMPANY_DATA_TEMPLATE")
# Email: test003@example.com
```

### Mixed Entity Types
```bash
# Counter: 0

# Create company (counter becomes 1)
COMPANY_DATA=$(get_unique_email "$COMPANY_DATA_TEMPLATE")
# Email: test001@example.com

# Create supplier (counter becomes 2)
SUPPLIER_DATA=$(get_unique_email "$SUPPLIER_DATA_TEMPLATE")  
# Email: supplier002@example.org

# Create user (counter becomes 3)
USER_DATA=$(get_unique_email "$USER_DATA_TEMPLATE")
# Email: test003@example.com

# Create customer (counter becomes 4)
CUSTOMER_DATA=$(get_unique_email "$CUSTOMER_DATA_TEMPLATE")
# Email: customer004@example.org
```

### Test Output
When running tests, you'll see unique emails in the output:
```
========================================
COMPANY MANAGEMENT - CREATE
========================================

TEST: Create new company
✓ PASS: Create company successful
ℹ INFO: Company ID: 12345
ℹ INFO: Email used: test001@example.com

========================================
USER MANAGEMENT - CREATE
========================================

TEST: Create new user
✓ PASS: Create user successful
ℹ INFO: User ID: 67890
ℹ INFO: Email used: test002@example.com
```

## Customization

### Change Email Domain
Edit the templates in the script:
```bash
# Change from example.com to yourcompany.com
COMPANY_DATA_TEMPLATE='{
  "email": "testXXX@yourcompany.com",
  ...
}'
```

### Change Prefix
```bash
# Change from "test" to "demo"
COMPANY_DATA_TEMPLATE='{
  "email": "demoXXX@example.com",
  ...
}'
```

### Add New Entity Types
```bash
# Add a new template with XXX placeholder
PARTNER_DATA_TEMPLATE='{
  "email": "partnerXXX@example.com",
  ...
}'

# Use in test function
test_create_partner() {
    local PARTNER_DATA=$(get_unique_email "$PARTNER_DATA_TEMPLATE")
    # Email will be partner005@example.com (if counter is at 5)
}
```

## Troubleshooting

### Issue: Duplicate Emails
**Problem:** Getting duplicate email errors  
**Solution:** Ensure you're using `get_unique_email()` for all entity creation that requires emails

### Issue: Counter Not Incrementing  
**Problem:** All emails have same number  
**Solution:** Check that you're calling `get_unique_email()` each time, not reusing the result

### Issue: Need More Than 999 Entities
**Problem:** Counter wraps around after 999  
**Solution:** Modify the counter logic to use 4 digits (0001-9999):
```bash
local formatted_counter=$(printf "%04d" $EMAIL_COUNTER)
if [ $EMAIL_COUNTER -gt 9999 ]; then
    EMAIL_COUNTER=1
fi
```

## Best Practices

### ✅ DO:
- Use templates with XXX or xxx placeholders
- Call `get_unique_email()` for each new entity
- Keep counter global for sequential numbering
- Add email info to success messages for debugging

### ❌ DON'T:
- Reuse the same generated data for multiple entities
- Manually set email addresses (defeats the purpose)
- Reset counter mid-script (breaks uniqueness)
- Use numbers other than XXX in templates (will be replaced)

## Summary

The unique email generation system:
- 🔢 **Automatically numbers emails** from 001 to 999
- 🔄 **Prevents duplicates** across test runs
- 📝 **Works with any template** containing XXX or xxx
- 🎯 **Simple to use** - just call `get_unique_email()`
- 📊 **Easy to track** - sequential numbering shows test order

This ensures reliable, repeatable testing without manual email management!
