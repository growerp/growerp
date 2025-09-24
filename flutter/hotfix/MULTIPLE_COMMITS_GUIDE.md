# Multiple Commit Selection Examples

This document provides practical examples of using the multiple commit selection feature in the GrowERP Hot Fix Release Tool.

## Selection Syntax

### Single Commit Selection
```bash
# By commit number
Select commit(s): 1

# By commit hash (full or partial)
Select commit(s): a1b2c3d
Select commit(s): a1b2c3d4e5f6789
```

### Multiple Commit Selection
```bash
# By commit numbers
Select commit(s): 1,3,5,7

# By commit hashes
Select commit(s): a1b2c3d,e4f5g6h,i7j8k9l

# Mixed (numbers and hashes)
Select commit(s): 1,e4f5g6h,5
```

### Range Selection
```bash
# Simple range
Select commit(s): 1-3    # Commits 1, 2, 3

# Larger range
Select commit(s): 2-6    # Commits 2, 3, 4, 5, 6
```

## Real-World Scenarios

### Scenario 1: Security Patch Bundle
```
Available commits:
  1. a1b2c3d Fix SQL injection vulnerability
  2. e4f5g6h Update dependency versions
  3. i7j8k9l Patch XSS vulnerability
  4. m1n2o3p Add input validation
  5. q5r6s7t Fix authentication bypass

Selection: 1,3,4,5
Result: Comprehensive security hotfix with 4 related commits
```

### Scenario 2: Bug Fix Series
```
Available commits:
  1. a1b2c3d Fix user registration bug
  2. e4f5g6h Update email validation
  3. i7j8k9l Fix password reset issue
  4. m1n2o3p Improve error messages
  5. q5r6s7t Add logging for debugging

Selection: 1-4
Result: Complete bug fix series with improved UX
```

### Scenario 3: Performance Improvements
```
Available commits:
  1. a1b2c3d Optimize database queries
  2. e4f5g6h Add caching layer
  3. i7j8k9l Reduce memory usage
  4. m1n2o3p Improve API response times
  5. q5r6s7t Update configuration

Selection: 1,2,4
Result: Targeted performance improvements without config changes
```

## Conflict Resolution Workflow

When applying multiple commits, conflicts may occur:

```
Applying commit 2/4: e4f5g6h Update user authentication logic
❌ Failed to cherry-pick commit e4f5g6h
This might be due to conflicts. Please resolve manually:
  1. Fix conflicts in the listed files
  2. Run: git add <resolved-files>
  3. Run: git cherry-pick --continue
  4. Continue with remaining commits manually or re-run script

How do you want to proceed?
  a) Abort cherry-pick and exit
  b) Skip this commit and continue with next
  c) Assume conflicts will be resolved manually and continue
  [a/b/c]: c
```

### Resolution Options

- **Option A (Abort)**: Safest option, stops the process
- **Option B (Skip)**: Continues without the problematic commit
- **Option C (Continue)**: For advanced users who will resolve manually

## Best Practices

### 1. Commit Application Order
**Important**: Commits are automatically applied in chronological order (oldest to newest) regardless of selection order.

```bash
# These selections result in the same application order:
Select commit(s): 1,2,3,4    # Applied as: 4,3,2,1 (oldest to newest)  
Select commit(s): 4,1,3,2    # Applied as: 4,3,2,1 (oldest to newest)
Select commit(s): 1-4        # Applied as: 4,3,2,1 (oldest to newest)
```

**Why chronological order?**
- Reduces merge conflicts
- Maintains proper commit dependencies  
- Preserves logical development sequence

### 2. Related Commits
Group related functionality together:
```bash
# Good: All authentication-related
Select commit(s): 1,3,5  # All auth fixes

# Good: All performance-related  
Select commit(s): 2,4,6  # All performance improvements
```

### 3. Test Dependencies
Consider commit dependencies:
```bash
# If commit 3 depends on commit 2:
Select commit(s): 2,3  # Include both

# Don't select only:
Select commit(s): 3     # Might fail without commit 2
```

### 4. Batch Size
Keep batches manageable:
```bash
# Good: Reasonable batch size
Select commit(s): 1-5

# Risky: Too many commits
Select commit(s): 1-15  # Higher chance of conflicts
```

## Common Patterns

### Security Hotfix Pattern
```bash
# Typical security hotfix bundle
Select commit(s): 1,3,5,7
# Where odd numbers are security-related commits
```

### Feature Completion Pattern  
```bash
# Complete a partially merged feature
Select commit(s): 2-4
# Sequential commits that complete a feature
```

### Selective Cherry-Pick Pattern
```bash
# Pick only specific fixes, skip others
Select commit(s): 1,4,6,9
# Skip commits 2,3,5,7,8 that aren't needed
```

## Tips for Success

1. **Review commit messages** carefully before selection
2. **Start with fewer commits** if unsure about conflicts
3. **Test each hotfix** in staging before production
4. **Document your selection** rationale for team reference
5. **Use branch reuse** for multiple hotfixes on same base version