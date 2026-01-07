# Registration and Login Process Refactoring - Test Plan

## 1. Overview

This document outlines the comprehensive test plan for the Registration and Login Process in GrowERP. The authentication system involves multiple flows, forms, and backend interactions that must be thoroughly tested.

### 1.1 Components Under Test

| Component | Location | Description |
|-----------|----------|-------------|
| `AuthBloc` | `growerp_core/lib/src/domains/authenticate/blocs/auth_bloc.dart` | Main BLoC handling authentication state |
| `LoginDialog` | `growerp_core/lib/src/domains/authenticate/views/login_dialog.dart` | Multi-form login dialog |
| `RegisterUserDialog` | `growerp_core/lib/src/domains/authenticate/views/register_user_dialog.dart` | User registration dialog |
| `TenantSetupDialog` | `growerp_core/lib/src/domains/authenticate/views/tenant_setup_dialog.dart` | Company setup for new admins |
| `TrialWelcomeHelper` | `growerp_core/lib/src/domains/authenticate/views/trial_welcome_helper.dart` | Trial welcome dialog helper |
| `PaymentSubscriptionDialog` | `growerp_core/lib/src/domains/authenticate/views/payment_subscription_dialog.dart` | Subscription payment dialog |
| `SendResetPasswordDialog` | `growerp_core/lib/src/domains/authenticate/views/send_reset_password_dialog.dart` | Password reset dialog |

### 1.2 Authentication States

```dart
enum AuthStatus {
  initial,
  sendPassword,
  loading,
  authenticated,
  unAuthenticated,
  failure,
  changeIp,
}
```

### 1.3 Backend API Key Values (Flow Control)

| API Key Value | Description | Form Displayed |
|---------------|-------------|----------------|
| `setupRequired` | Admin needs to provide company info | `TenantSetupDialog` |
| `trialWelcome` | New tenant, show trial welcome | `TrialWelcomeDialog` |
| `subscriptionExpired` | Subscription expired, payment required | `PaymentSubscriptionDialog` |
| `registered` | User registered for existing company | `loginForm()` |
| `passwordChange` | Password reset required | `changePasswordForm()` |
| `moreInfo` | (Legacy) Replaced by `setupRequired` | `moreInfoForm()` |
| `evaluationWelcome` | (Legacy) Replaced by `trialWelcome` | `evaluationWelcomeForm()` |
| `paymentFirst/paymentExpired/paymentExpiredFinal` | (Legacy) Replaced by `subscriptionExpired` | `paymentForm()` |

---

## 2. Test Scenarios

### 2.1 Registration Flow Tests

#### TC-REG-001: New Admin User Registration (New Company)
**Objective:** Verify a new admin user can register and create a new company.

**Preconditions:**
- No existing user with the test email
- Backend is running

**Steps:**
1. Navigate to login screen
2. Tap "New User" button (`newUserButton`)
3. Enter first name, last name, email
4. Submit registration form (`newUserButton`)
5. Verify registration success message
6. Login with temporary password sent by email

**Expected Results:**
- Registration form accepts valid input
- Success message displayed: "Registration successful..."
- `AuthStatus.unAuthenticated` emitted with success message
- User can proceed to login

**Test Keys:**
- `firstName`, `lastName`, `email`, `newUserButton`

---

#### TC-REG-002: New Non-Admin User Registration (Existing Company)
**Objective:** Verify a non-admin user can register for an existing company.

**Preconditions:**
- Company already exists
- `Company` is provided via context

**Steps:**
1. Navigate to registration dialog
2. Enter user details
3. Submit registration
4. Login with password from email

**Expected Results:**
- User registered under specified company
- `AuthStatus.unAuthenticated` emitted
- User can login successfully

---

#### TC-REG-003: Registration with Invalid Email
**Objective:** Verify email validation works correctly.

**Steps:**
1. Navigate to registration
2. Enter invalid email formats (e.g., "test", "test@", "@example.com")
3. Submit form

**Expected Results:**
- Form validation error displayed
- Registration not submitted

---

#### TC-REG-004: Registration with Duplicate Email
**Objective:** Verify duplicate email handling.

**Steps:**
1. Register a new user
2. Try to register with same email

**Expected Results:**
- `AuthStatus.failure` emitted
- Error message displayed

---

### 2.2 Login Flow Tests

#### TC-LOGIN-001: Successful Login with Valid Credentials
**Objective:** Verify successful login flow.

**Preconditions:**
- User exists with valid credentials

**Steps:**
1. Navigate to login screen
2. Tap login button (`loginButton`)
3. Enter username and password
4. Tap login (`login`)

**Expected Results:**
- `AuthStatus.authenticated` emitted
- User navigated to home/dashboard
- Trial welcome shown if applicable

**Test Keys:**
- `loginButton`, `username`, `password`, `login`

---

#### TC-LOGIN-002: Login with Invalid Credentials
**Objective:** Verify error handling for invalid login.

**Steps:**
1. Navigate to login
2. Enter incorrect username/password
3. Submit login

**Expected Results:**
- `AuthStatus.failure` emitted
- Error message displayed (red snackbar)
- Login form remains displayed

---

#### TC-LOGIN-003: Login with Empty Fields
**Objective:** Verify form validation.

**Steps:**
1. Leave username empty, submit
2. Leave password empty, submit

**Expected Results:**
- Validation errors displayed for required fields

---

#### TC-LOGIN-004: Password Visibility Toggle
**Objective:** Verify password visibility toggle works.

**Steps:**
1. Enter password
2. Tap visibility toggle icon
3. Verify password visible
4. Tap again to hide

**Expected Results:**
- Password toggles between hidden (•••) and visible states

---

### 2.3 Tenant Setup Flow Tests

#### TC-SETUP-001: Complete Tenant Setup (Admin)
**Objective:** Verify admin can complete tenant setup after registration.

**Preconditions:**
- Admin registered, backend returns `setupRequired`

**Steps:**
1. Login as new admin
2. `TenantSetupDialog` displayed
3. Enter company name
4. Select currency
5. Toggle demo data checkbox
6. Submit setup (`submit`)

**Expected Results:**
- `AuthLogin` event dispatched with company info
- `AuthStatus.authenticated` emitted
- Trial welcome dialog shown
- User navigated to dashboard

**Test Keys:**
- `companyName`, `currency`, `demoData`, `submit`, `cancel`

---

#### TC-SETUP-002: Cancel Tenant Setup
**Objective:** Verify cancel button works.

**Steps:**
1. Open tenant setup dialog
2. Tap cancel (`cancel`)

**Expected Results:**
- Dialog closed
- User returned to login

---

#### TC-SETUP-003: Tenant Setup with Demo Data
**Objective:** Verify demo data creation during setup.

**Steps:**
1. Complete tenant setup with demo data enabled
2. Verify extended timeout used (15 minutes)

**Expected Results:**
- Demo data loaded successfully
- User can see demo products, orders, etc.

---

### 2.4 Trial/Evaluation Period Tests

#### TC-TRIAL-001: Trial Welcome Dialog Display (New Tenant)
**Objective:** Verify trial welcome shown to new tenants.

**Preconditions:**
- New tenant (not GROWERP)
- Trial welcome not yet shown

**Steps:**
1. Complete registration and setup
2. Verify trial welcome dialog

**Expected Results:**
- Trial welcome dialog displayed
- Shows company name, user name, trial days
- "Get Started" button closes dialog (`getStarted`)

---

#### TC-TRIAL-002: Trial Welcome Not Shown Again
**Objective:** Verify trial welcome only shown once per tenant.

**Steps:**
1. Complete initial login (trial welcome shown)
2. Logout
3. Login again

**Expected Results:**
- Trial welcome NOT shown on second login
- SharedPreferences tracks shown state

---

#### TC-TRIAL-003: Trial Welcome Not Shown for GROWERP Tenant
**Objective:** Verify system tenant skips trial welcome.

**Steps:**
1. Login as GROWERP owner

**Expected Results:**
- Trial welcome dialog NOT shown

---

### 2.5 Subscription/Payment Tests

#### TC-PAY-001: Payment Form Display (Subscription Expired)
**Objective:** Verify payment form shown when subscription expires.

**Preconditions:**
- User has expired subscription

**Steps:**
1. Login with expired subscription user
2. Backend returns `subscriptionExpired`

**Expected Results:**
- Payment form displayed (`paymentForm`)
- Shows subscription plans
- Shows credit card input fields

**Test Keys:**
- `paymentForm`, `plan`, `cardNumber`, `expiryDate`, `cvvCode`, `cardHolderName`, `pay`

---

#### TC-PAY-002: Successful Payment Submission
**Objective:** Verify payment processing works.

**Steps:**
1. Fill in payment form with test card (4242424242424242)
2. Select plan
3. Submit payment (`pay`)

**Expected Results:**
- Payment processed
- `AuthStatus.authenticated` emitted
- User navigated to dashboard

---

#### TC-PAY-003: Payment Form Pre-filled in Test Mode
**Objective:** Verify test data auto-filled in non-release mode.

**Preconditions:**
- Running in debug mode OR `test=true` in config

**Expected Results:**
- Card number: 4242424242424242
- Expiry: 11/33
- CVV: 123
- Name: Test Customer

---

### 2.6 Password Change/Reset Tests

#### TC-PWD-001: Password Reset Request
**Objective:** Verify password reset email sent.

**Steps:**
1. Navigate to login
2. Tap "Forgot Password?"
3. Enter email in reset dialog
4. Submit

**Expected Results:**
- `AuthStatus.sendPassword` → `AuthStatus.unAuthenticated`
- Success message displayed
- Email sent to user

**Test Keys:**
- `username` (in reset dialog), submit button

---

#### TC-PWD-002: Change Password Form (First Login)
**Objective:** Verify new password creation works.

**Preconditions:**
- Backend returns `passwordChange`

**Steps:**
1. Login with temporary password
2. Change password form displayed
3. Enter new password meeting requirements
4. Confirm password
5. Submit (`submitNewPassword` via form)

**Expected Results:**
- Password changed successfully
- `AuthStatus.authenticated` emitted
- User logged in

**Password Requirements:**
- 8+ characters
- Contains letter, number, and special character (!@#$%^&+=)

---

#### TC-PWD-003: Password Mismatch Validation
**Objective:** Verify password confirmation validation.

**Steps:**
1. Enter password
2. Enter different confirmation password
3. Submit

**Expected Results:**
- Validation error displayed

---

### 2.7 Session/State Persistence Tests

#### TC-SESS-001: Auto-Login with Valid Session
**Objective:** Verify user auto-logged in if session valid.

**Preconditions:**
- Previous valid session exists in local storage

**Steps:**
1. Start app
2. `AuthLoad` event processed

**Expected Results:**
- `AuthStatus.authenticated` emitted
- User navigated to dashboard without login

---

#### TC-SESS-002: Session Expired - Redirect to Login
**Objective:** Verify expired session handled.

**Steps:**
1. Start app with expired session
2. Backend rejects API key

**Expected Results:**
- `AuthStatus.unAuthenticated` emitted
- Login screen displayed

---

#### TC-SESS-003: Logout Flow
**Objective:** Verify logout clears session.

**Steps:**
1. While logged in, navigate to logout
2. Confirm logout

**Expected Results:**
- `AuthLoggedOut` event processed
- `AuthStatus.unAuthenticated` emitted
- Session cleared from local storage
- Login screen displayed

---

### 2.8 Navigation Tests

#### TC-NAV-001: Login Dialog as Page vs Dialog
**Objective:** Verify navigation behavior differs based on context.

**Steps:**
1. Open LoginDialog as dialog (via `showDialog`)
2. Complete login
3. Verify `Navigator.pop()` called

**Steps (Alt):**
1. Open LoginDialog as GoRouter page
2. Complete login
3. Verify `context.go('/')` called (not pop)

**Expected Results:**
- Correct navigation action based on context
- No assertion errors

---

#### TC-NAV-002: TenantSetupDialog Dismissal
**Objective:** Verify setup dialog dismisses correctly.

**Steps:**
1. Complete tenant setup
2. Verify dialog closes
3. Verify trial welcome appears
4. Dismiss trial welcome
5. Verify dashboard displayed

**Expected Results:**
- Smooth transition between dialogs
- No multiple dialogs displayed

---

### 2.9 Error Handling Tests

#### TC-ERR-001: Network Error During Login
**Objective:** Verify network error handling.

**Steps:**
1. Disable network
2. Attempt login

**Expected Results:**
- `AuthStatus.failure` emitted
- Error message displayed
- User can retry

---

#### TC-ERR-002: Backend Error Response
**Objective:** Verify backend error parsing.

**Steps:**
1. Trigger backend error (e.g., invalid input)

**Expected Results:**
- Error message from `getDioError()` displayed
- State remains functional

---

### 2.10 Localization Tests

#### TC-L10N-001: Login Screen Localization
**Objective:** Verify login screens are localized.

**Steps:**
1. Change app locale
2. Navigate to login screens

**Expected Results:**
- All labels translated
- Error messages translated

---

## 3. Integration Test Implementation

### 3.1 Existing Test Files

| File | Location | Coverage |
|------|----------|----------|
| `auth_test.dart` | `growerp_core/lib/src/domains/authenticate/integration_test/` | Basic auth helpers |
| `evaluation_test.dart` | `growerp_core/lib/src/domains/authenticate/integration_test/` | Evaluation period tests |
| `evaluation_test.dart` | `growerp_core/example/integration_test/` | Full evaluation flow tests |

### 3.2 Test Helpers

```dart
class AuthTest {
  // High-level tests
  static Future<void> createNewAdminAndCompany(tester, user, company);
  static Future<void> login(tester, loginName, password);
  static Future<void> loginIfRequired(tester, loginName, password);
  
  // Low-level helpers
  static Future<void> pressNewCompany(tester);
  static Future<void> enterFirstName(tester, name);
  static Future<void> enterLastname(tester, name);
  static Future<void> enterEmailAddress(tester, email);
  static Future<void> enterCompanyName(tester, name);
  static Future<void> enterCurrency(tester, currency);
  static Future<void> clearDemoData(tester);
  static Future<void> pressLoginWithExistingId(tester);
  static Future<void> enterLoginName(tester, name);
  static Future<void> enterPassword(tester, password);
  static Future<void> pressLogin(tester);
}
```

### 3.3 Evaluation Test Helpers

```dart
class EvaluationTest {
  static void setTestDaysOffset(int daysOffset);
  static void resetTestDaysOffset();
  static Future<bool> isEvaluationWelcomeDisplayed(tester);
  static Future<bool> isPaymentFormDisplayed(tester);
  static Future<void> startEvaluation(tester);
  static Future<void> checkEvaluationWelcomeContent(tester, {expectedDays});
  static Future<void> checkPaymentFormContent(tester);
  static Future<bool> submitPayment(tester);
  static Future<String> verifyRegistrationForm(tester);
}
```

---

## 4. Test Data

### 4.1 Default Test Credentials (Debug Mode)

```dart
// Login
username: 'test@example.com' (or 'SystemSupport' for AppSupport)
password: 'qqqqqq9!' (or 'moqui' for AppSupport)

// Registration
firstName: 'John'
lastName: 'Doe'
email: 'test@example.com'

// Company
companyName: 'Main Company'
currency: USD (index 1)
demoData: true (debug), false (release)
```

### 4.2 Test Credit Card Data

```dart
cardNumber: '4242424242424242'
expiryDate: '11/33'
cvvCode: '123'
nameOnCard: 'Test Customer'
```

---

## 5. Test Execution

### 5.1 Running Tests Locally

```bash
cd flutter/packages/growerp_core/example
flutter test integration_test/evaluation_test.dart
```

### 5.2 Running Tests with Melos

```bash
melos test
```

### 5.3 Running Tests in Docker (Headless)

```bash
./build_run_all_tests.sh
```

---

## 6. Test Coverage Matrix

| Test Category | Unit Tests | Integration Tests | Manual Tests |
|---------------|------------|-------------------|--------------|
| Registration | ❌ | ✅ | ✅ |
| Login | ❌ | ✅ | ✅ |
| Tenant Setup | ❌ | ⚠️ (partial) | ✅ |
| Trial Welcome | ❌ | ⚠️ (partial) | ✅ |
| Payment | ❌ | ✅ | ✅ |
| Password Reset | ❌ | ❌ | ✅ |
| Session Persistence | ❌ | ⚠️ (implicit) | ✅ |
| Error Handling | ❌ | ⚠️ (implicit) | ✅ |

**Legend:** ✅ Covered | ⚠️ Partially Covered | ❌ Not Covered

---

## 7. Priority and Risks

### 7.1 High Priority Tests
1. TC-REG-001: New Admin Registration
2. TC-LOGIN-001: Successful Login
3. TC-SETUP-001: Complete Tenant Setup
4. TC-TRIAL-003: Subscription Expired Payment

### 7.2 Risks
1. **Demo data creation timeout** - Extended timeout (15 min) for demo data
2. **State synchronization** - Multiple dialogs and navigation transitions
3. **Legacy API key handling** - Backward compatibility during migration
4. **Network/backend failures** - Graceful error handling needed

---

## 8. Appendix: UI Keys Reference

### 8.1 Login Dialog Keys
- `loginButton` - Open login form
- `newCompButton` - Open new company registration
- `newUserButton` - Open user registration / submit registration
- `username` - Username/email input
- `password` - Password input
- `password2` - Password confirmation
- `login` - Submit login
- `continue` - Continue button in moreInfo form
- `startEvaluation` - Start evaluation period
- `pay` - Submit payment

### 8.2 Tenant Setup Dialog Keys
- `companyName` - Company name input
- `currency` - Currency dropdown
- `demoData` - Demo data checkbox
- `submit` - Submit setup
- `cancel` - Cancel setup

### 8.3 Trial Welcome Dialog Keys
- `getStarted` - Dismiss trial welcome

### 8.4 Payment Form Keys
- `paymentForm` - Payment form container
- `plan` - Plan selection
- `cardNumber` - Credit card number
- `expiryDate` - Expiry date
- `cvvCode` - CVV code
- `cardHolderName` - Name on card

---

*Document Version: 1.0*
*Last Updated: 2026-01-05*
*Authors: AI Coding Assistant*
