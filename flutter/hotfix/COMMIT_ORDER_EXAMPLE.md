# Commit Application Order Example

This example demonstrates how commits are applied in chronological order.

## Scenario Setup

Imagine you have these commits on master since your base tag:

```
git log --oneline v1.3.42..master

c3d4e5f Fix user interface bug      ← Commit #1 (newest)
b2c3d4e Update API documentation    ← Commit #2  
a1b2c3d Fix database connection     ← Commit #3 (oldest)
```

## Selection vs Application Order

### User Selection: `1,3` (Fix UI bug + Fix database)

**What user sees:**
```
Selected commits to apply (in selection order):
  - c3d4e5f Fix user interface bug
  - a1b2c3d Fix database connection

Note: Commits will be applied in chronological order (oldest to newest) to reduce conflicts.
```

**How commits are applied:**
```
Applying commits in chronological order (oldest to newest):
  - a1b2c3d Fix database connection
  - c3d4e5f Fix user interface bug

Applying commit 1/2: a1b2c3d Fix database connection
✓ Commit a1b2c3d applied successfully

Applying commit 2/2: c3d4e5f Fix user interface bug  
✓ Commit c3d4e5f applied successfully
```

## Why Chronological Order?

### 1. Dependency Resolution
```
# Commit timeline:
Day 1: a1b2c3d Fix database connection
Day 2: b2c3d4e Update API documentation (depends on DB fix)
Day 3: c3d4e5f Fix user interface bug (depends on API update)

# If applied out of order (c3d4e5f → a1b2c3d):
# c3d4e5f might fail because it expects the DB fix to be present
```

### 2. Conflict Reduction
```
# Chronological order maintains the natural evolution:
a1b2c3d → b2c3d4e → c3d4e5f
   ↓         ↓         ↓
  DB fix → API docs → UI fix

# Random order might create artificial conflicts:
c3d4e5f → a1b2c3d
   ↓         ↓
UI fix → DB fix (conflicts with UI changes)
```

### 3. Logical Development Flow
```
# Natural development sequence:
1. Fix foundation (database)
2. Update documentation  
3. Fix user interface

# Maintains the logical progression of changes
```

## Range Selection Example

### User Selection: `1-3` (All commits)

**Application order:**
```
Selection: 1-3
Commits selected: c3d4e5f, b2c3d4e, a1b2c3d
Application order: a1b2c3d → b2c3d4e → c3d4e5f

Result: All commits applied in chronological sequence
```

## Multiple Hotfix Scenarios

### Scenario 1: Security Patches
```
# Commits available:
1. d4e5f6g Patch XSS vulnerability    (newest)
2. c3d4e5f Update input validation
3. b2c3d4e Fix SQL injection          
4. a1b2c3d Improve authentication     (oldest)

# Selection: 1,3,4 (Skip documentation update)
# Application: a1b2c3d → b2c3d4e → d4e5f6g
```

### Scenario 2: Feature Completion
```
# Commits available:
1. d4e5f6g Add feature tests          (newest)
2. c3d4e5f Implement feature UI
3. b2c3d4e Add feature API endpoints
4. a1b2c3d Create feature database     (oldest)

# Selection: 2-4 (Skip tests for now)  
# Application: a1b2c3d → b2c3d4e → c3d4e5f
```

## Best Practices

1. **Trust the chronological order** - it's designed to minimize conflicts
2. **Select related commits** that logically belong together
3. **Consider dependencies** when choosing which commits to include
4. **Test thoroughly** after applying multiple commits
5. **Document your rationale** for commit selection in release notes