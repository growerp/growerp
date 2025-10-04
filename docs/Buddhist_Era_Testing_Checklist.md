# Buddhist Era - Manual Testing Checklist

## 🎯 Testing Overview

This checklist ensures the Buddhist Era date formatting works correctly across all migrated features.

---

## 📋 Pre-Testing Setup

### Environment Setup
- [ ] Build app: `cd flutter && melos build`
- [ ] Start backend: `cd moqui && java -jar moqui.war`
- [ ] Launch app on emulator/device

### Test Data Preparation
- [ ] Create at least 3 subscriptions with different dates
- [ ] Create at least 5 orders with various dates
- [ ] Create at least 2 invoices
- [ ] Make at least 1 payment transaction

---

## 🇹🇭 PART 1: Thai Language Testing

### Step 1: Switch to Thai Language
- [ ] Open app
- [ ] Go to Settings/Home
- [ ] Click language selector (🌐 icon)
- [ ] Select "ไทย (Thai)"
- [ ] Verify interface changes to Thai

### Step 2: Test Subscription Dates
Navigate to Subscriptions list:

- [ ] **Subscription List Table**
  - [ ] Verify "From Date" shows Buddhist Era (25XX)
  - [ ] Verify "Thru Date" shows Buddhist Era (25XX)
  - [ ] Verify "Purchase From Date" shows Buddhist Era
  - [ ] Verify "Purchase Thru Date" shows Buddhist Era
  - [ ] Take screenshot for documentation

- [ ] **Subscription Dialog**
  - [ ] Open an existing subscription
  - [ ] Verify "Purchased" date shows Buddhist Era
  - [ ] Verify "Cancelled" date shows Buddhist Era
  - [ ] Take screenshot

### Step 3: Test Order/Invoice Dates
Navigate to Orders:

- [ ] **Order List (Phone View)**
  - [ ] If hotel app: Verify rental date shows Buddhist Era
  - [ ] If other apps: Verify placed/creation date shows Buddhist Era
  - [ ] Scroll through several orders
  - [ ] Take screenshot

- [ ] **Order List (Desktop View - if available)**
  - [ ] Verify "Reservation Date" or "Creation Date" shows Buddhist Era
  - [ ] Check multiple orders
  - [ ] Take screenshot

- [ ] **Order Detail Dialog**
  - [ ] Open an order
  - [ ] Verify "Created:" date shows Buddhist Era
  - [ ] Verify "Placed:" date shows Buddhist Era
  - [ ] For rental items: Verify "Date:" shows Buddhist Era
  - [ ] Take screenshot

### Step 4: Test Payment Dates
Navigate to Payments:

- [ ] **Payment History Table**
  - [ ] Verify transaction dates show Buddhist Era
  - [ ] Check multiple payment records
  - [ ] Take screenshot

### Step 5: Test Search Function
Use search feature:

- [ ] **Search Results**
  - [ ] Search for orders/invoices
  - [ ] Verify creation dates in results show Buddhist Era
  - [ ] Format: "ID: xxx Date: 25XX-XX-XX"
  - [ ] Take screenshot

### Step 6: Verify Date Calculations
Test date picker and calculations:

- [ ] **Create New Order**
  - [ ] Open date picker
  - [ ] Note: Picker shows Gregorian (Flutter limitation - OK)
  - [ ] Select a date
  - [ ] Verify displayed date (after selection) shows Buddhist Era
  - [ ] Save order
  - [ ] Verify saved date displays correctly

### Step 7: Test Mobile View (if applicable)
- [ ] Switch to mobile view/phone mode
- [ ] Verify all dates still show Buddhist Era
- [ ] Check condensed views show correctly

---

## 🇬🇧 PART 2: English Language Testing

### Step 8: Switch to English
- [ ] Open Settings/Home
- [ ] Click language selector
- [ ] Select "English"
- [ ] Verify interface changes to English

### Step 9: Verify Gregorian Dates
Test same features as above:

- [ ] **Subscriptions**
  - [ ] Verify all dates show Gregorian (2025, 2026, etc.)
  - [ ] Should be different from Thai view
  - [ ] Take screenshot

- [ ] **Orders/Invoices**
  - [ ] Verify all dates show Gregorian
  - [ ] Take screenshot

- [ ] **Payments**
  - [ ] Verify transaction dates show Gregorian
  - [ ] Take screenshot

- [ ] **Search**
  - [ ] Verify search results show Gregorian
  - [ ] Take screenshot

---

## 💾 PART 3: Database Integrity Testing

### Step 10: Verify Database Data
Using database viewer or API:

- [ ] **Check Subscription Table**
  ```sql
  SELECT subscription_id, from_date, thru_date FROM Subscription;
  ```
  - [ ] Verify dates are Gregorian (2025, 2026, etc.)
  - [ ] NOT Buddhist Era (should not see 2568, 2569, etc.)

- [ ] **Check Order Table**
  ```sql
  SELECT order_id, order_date, entry_date FROM OrderHeader;
  ```
  - [ ] Verify all dates are Gregorian

- [ ] **Check Payment Table**
  ```sql
  SELECT payment_id, effective_date FROM Payment;
  ```
  - [ ] Verify all dates are Gregorian

### Step 11: API Response Check
Using browser dev tools or API client:

- [ ] **Make API Request**
  - [ ] Open browser developer tools (F12)
  - [ ] Navigate to Network tab
  - [ ] Load subscriptions/orders
  - [ ] Check API response JSON
  - [ ] Verify dates in JSON are Gregorian format
  - [ ] Example: `"fromDate": "2025-10-04T..."`

---

## 🧪 PART 4: Locale Switching Testing

### Step 12: Rapid Switching
- [ ] Switch Thai → English → Thai → English
- [ ] Verify dates update immediately each time
- [ ] No app restart required
- [ ] No errors or glitches
- [ ] All dates remain consistent

### Step 13: Data Entry While Switching
- [ ] Start creating an order in Thai
- [ ] Note the displayed date
- [ ] Switch to English mid-creation
- [ ] Complete the order
- [ ] Switch back to Thai
- [ ] Verify order displays correctly in both languages

---

## 🔍 PART 5: Edge Cases Testing

### Step 14: Null/Empty Dates
- [ ] Find or create record with null dates
- [ ] Verify empty string displayed (not error)
- [ ] In Thai locale
- [ ] In English locale

### Step 15: Date Ranges
- [ ] Test "From Date" and "Thru Date" pairs
- [ ] Verify both show same calendar system
- [ ] Verify difference makes sense

### Step 16: Old Data
- [ ] Check records from previous years
- [ ] Verify year conversion correct:
  - 2020 → 2563 (Thai)
  - 2021 → 2564 (Thai)
  - 2024 → 2567 (Thai)

### Step 17: Future Dates
- [ ] Create order with future date
- [ ] Verify conversion:
  - 2026 → 2569 (Thai)
  - 2030 → 2573 (Thai)

---

## 🧪 PART 6: Integration Testing

### Step 18: Full Workflow - Thai User
As a Thai user:

- [ ] Create new subscription
- [ ] Set dates via picker
- [ ] Save
- [ ] View in list (should show BE)
- [ ] Edit subscription
- [ ] Verify dates still correct
- [ ] Delete subscription

### Step 19: Full Workflow - English User
Switch to English and repeat:

- [ ] Create new order
- [ ] Set dates
- [ ] Save
- [ ] View in list (should show Gregorian)
- [ ] Edit order
- [ ] Process payment
- [ ] Verify all dates Gregorian

### Step 20: Cross-Locale Verification
- [ ] Create record in Thai (see BE dates)
- [ ] Switch to English (same record, see Gregorian)
- [ ] Verify it's the same record (same ID)
- [ ] Verify date values logically consistent
  - Thai: 2568-10-04
  - English: 2025-10-04
  - Same day, different calendar!

---

## 📊 PART 7: Performance Testing

### Step 21: Load Testing
- [ ] Load page with 100+ orders
- [ ] Measure load time in Thai
- [ ] Switch to English
- [ ] Measure load time in English
- [ ] Verify no significant performance difference
- [ ] No lag or freezing

### Step 22: Scrolling Performance
- [ ] Scroll through long list of records
- [ ] In Thai locale
- [ ] In English locale
- [ ] Verify smooth scrolling
- [ ] No frame drops

---

## 🐛 PART 8: Error Scenarios

### Step 23: Invalid Dates
- [ ] Attempt to create invalid dates (if possible)
- [ ] Verify error handling works
- [ ] In both locales

### Step 24: Network Issues
- [ ] Disconnect network
- [ ] Try to load dates
- [ ] Verify graceful error handling
- [ ] Reconnect
- [ ] Verify recovery

---

## 📸 PART 9: Documentation

### Step 25: Screenshots Collection
Collect screenshots for documentation:

- [ ] Subscription list (Thai)
- [ ] Subscription list (English)
- [ ] Order detail (Thai)
- [ ] Order detail (English)
- [ ] Payment history (Thai)
- [ ] Payment history (English)
- [ ] Search results (Thai)
- [ ] Search results (English)

### Step 26: Video Recording (Optional)
- [ ] Record 2-minute demo:
  - Switch to Thai
  - Navigate through features
  - Show Buddhist Era dates
  - Switch to English
  - Show Gregorian dates
  - Demonstrate locale switching

---

## ✅ PART 10: Final Verification

### Step 27: Test Checklist Summary
Count and verify:

- [ ] All subscription dates: ✅ Buddhist Era for Thai
- [ ] All order dates: ✅ Buddhist Era for Thai
- [ ] All payment dates: ✅ Buddhist Era for Thai
- [ ] All search dates: ✅ Buddhist Era for Thai
- [ ] Database: ✅ Still Gregorian
- [ ] API responses: ✅ Still Gregorian
- [ ] Locale switching: ✅ Works instantly
- [ ] No errors: ✅ No crashes or exceptions

### Step 28: Sign-off
- [ ] **Testing completed by**: _________________
- [ ] **Date**: _________________
- [ ] **Issues found**: _________________
- [ ] **Overall status**: ☐ Pass  ☐ Fail  ☐ Needs fixes

---

## 🚨 Known Limitations (Expected Behavior)

These are NOT bugs:

1. **Date Picker Shows Gregorian**
   - ✅ EXPECTED: Flutter's DatePicker uses Gregorian internally
   - ✅ CORRECT: Selected date displays in Buddhist Era after selection

2. **Tests Use Gregorian**
   - ✅ EXPECTED: All tests use English locale
   - ✅ CORRECT: This is by design

3. **Database Stores Gregorian**
   - ✅ EXPECTED: Database always uses Gregorian
   - ✅ CORRECT: Ensures international compatibility

---

## 📞 Reporting Issues

If you find a problem:

1. **Describe the issue**:
   - What were you doing?
   - What locale were you using?
   - What did you expect?
   - What actually happened?

2. **Include evidence**:
   - Screenshot
   - Steps to reproduce
   - Console errors (if any)

3. **Report to**:
   - Development team
   - Include this testing checklist
   - Reference specific test numbers

---

## 🎯 Success Criteria

All tests pass if:

- ✅ Thai users see Buddhist Era dates consistently
- ✅ English users see Gregorian dates consistently
- ✅ Database remains in Gregorian format
- ✅ Locale switching works instantly
- ✅ No errors or crashes
- ✅ Performance is acceptable
- ✅ All features work in both locales

---

**Testing Checklist Version**: 1.0  
**Last Updated**: October 4, 2025  
**Total Test Cases**: 28 sections, 100+ individual checks
