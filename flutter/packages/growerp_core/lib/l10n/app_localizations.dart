import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// About app dialog title
  ///
  /// In en, this message translates to:
  /// **'About {appName}'**
  String aboutApp(String appName);

  /// About GrowERP menu item
  ///
  /// In en, this message translates to:
  /// **'About GrowERP'**
  String get aboutGrowERP;

  /// Accounts menu item or section header
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// Add new item button text
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// Partial validation message indicating minimum requirement
  ///
  /// In en, this message translates to:
  /// **'and at least one '**
  String get andAtLeastOne;

  /// Backend server input label
  ///
  /// In en, this message translates to:
  /// **'Backend Server'**
  String get backendServer;

  /// Balance sheet report menu item
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get balanceSheet;

  /// Balance summary report menu item
  ///
  /// In en, this message translates to:
  /// **'Balance Summary'**
  String get balanceSummary;

  /// Business name validation error message
  ///
  /// In en, this message translates to:
  /// **'Business company name required!'**
  String get businessCompanyName;

  /// Business name validation error message
  ///
  /// In en, this message translates to:
  /// **'Business name is required!'**
  String get businessNameError;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Error message when REST requests fail to load
  ///
  /// In en, this message translates to:
  /// **'Cannot load rest requests!'**
  String get cannotLoadRestRequests;

  /// Chat menu item
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Chat server input label
  ///
  /// In en, this message translates to:
  /// **'Chat Server'**
  String get chatServer;

  /// Complete registration dialog title
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// Company party ID input label
  ///
  /// In en, this message translates to:
  /// **'Company Party Id'**
  String get companyPartyId;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Contributing menu item
  ///
  /// In en, this message translates to:
  /// **'Contributing'**
  String get contributing;

  /// Copyright text with year
  ///
  /// In en, this message translates to:
  /// **'© {year} GrowERP.com'**
  String copyright(String year);

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Create password dialog title
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get createPassword;

  /// Credit card details hint text
  ///
  /// In en, this message translates to:
  /// **'Credit card details'**
  String get creditCardDetails;

  /// Credit card info label
  ///
  /// In en, this message translates to:
  /// **'Credit card info'**
  String get creditCardInfo;

  /// Currency input label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Currency validation error message
  ///
  /// In en, this message translates to:
  /// **'Currency is required!'**
  String get currencyError;

  /// Current payment method display text
  ///
  /// In en, this message translates to:
  /// **'Current payment method: {method}'**
  String currentPaymentMethod(String method);

  /// Label for customer
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// CVV code input label
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvvCode;

  /// CVV code input hint
  ///
  /// In en, this message translates to:
  /// **'123'**
  String get cvvHint;

  /// Date and time label
  ///
  /// In en, this message translates to:
  /// **'Date/Time'**
  String get dateTime;

  /// Delete warning dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Warning'**
  String get deleteWarning;

  /// Delete yourself button text
  ///
  /// In en, this message translates to:
  /// **'Delete yourself'**
  String get deleteYourself;

  /// Delete yourself and company button text
  ///
  /// In en, this message translates to:
  /// **'Delete yourself and company'**
  String get deleteYourselfAndCompany;

  /// Demo data checkbox label
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get demoData;

  /// Email input label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email address input label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Email address validation error message
  ///
  /// In en, this message translates to:
  /// **'Email address is required!'**
  String get emailAddressError;

  /// Email address format validation error message
  ///
  /// In en, this message translates to:
  /// **'Email address format incorrect!'**
  String get emailAddressError2;

  /// Enter backend URL dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter backend URL'**
  String get enterBackendUrl;

  /// Company and currency input instruction
  ///
  /// In en, this message translates to:
  /// **'Please enter your company name and currency'**
  String get enterCompanyAndCurrency;

  /// Company name input instruction
  ///
  /// In en, this message translates to:
  /// **'Enter company name'**
  String get enterCompanyName;

  /// Error status text
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error message label
  ///
  /// In en, this message translates to:
  /// **'Error message'**
  String get errorMessage;

  /// Expiry date input label
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get expiryDate;

  /// Expiry date input hint
  ///
  /// In en, this message translates to:
  /// **'12/25'**
  String get expiryDateHint;

  /// Field required validation error message
  ///
  /// In en, this message translates to:
  /// **'Field is required!'**
  String get fieldRequired;

  /// First name input label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// First name validation error message
  ///
  /// In en, this message translates to:
  /// **'First name is required!'**
  String get firstNameError;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Generate demo data checkbox text
  ///
  /// In en, this message translates to:
  /// **'Generate demo data?'**
  String get generateDemoData;

  /// Go home button tooltip
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// Label for invoice
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// Validation message indicating a required item
  ///
  /// In en, this message translates to:
  /// **'item is required'**
  String get itemIsRequired;

  /// Item types menu item or section header
  ///
  /// In en, this message translates to:
  /// **'Item Types'**
  String get itemTypes;

  /// Journal menu item or section header
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// Last name input label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Last name validation error message
  ///
  /// In en, this message translates to:
  /// **'Last name is required!'**
  String get lastNameError;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Login name label
  ///
  /// In en, this message translates to:
  /// **'Login name'**
  String get loginName;

  /// Login form header text for existing users
  ///
  /// In en, this message translates to:
  /// **'Login with Existing user name'**
  String get loginWithExistingUserName;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Main menu item
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// Main dashboard menu item or navigation link
  ///
  /// In en, this message translates to:
  /// **'Main Dashboard'**
  String get mainDashboard;

  /// Milliseconds abbreviation
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get ms;

  /// Name on card input label
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get nameOnCard;

  /// No answer text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No access error message
  ///
  /// In en, this message translates to:
  /// **'No access to this page!'**
  String get noAccess;

  /// No access here error message
  ///
  /// In en, this message translates to:
  /// **'No Access Here!'**
  String get noAccessHere;

  /// No REST requests message
  ///
  /// In en, this message translates to:
  /// **'No REST requests found...'**
  String get noRestRequests;

  /// Not available placeholder text
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// Number input label
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// Card number input hint
  ///
  /// In en, this message translates to:
  /// **'1234 5678 9012 3456'**
  String get numberHint;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Only delete user option text
  ///
  /// In en, this message translates to:
  /// **'Only delete user, not company'**
  String get onlyUserDelete;

  /// Label for open invoices dashboard item
  ///
  /// In en, this message translates to:
  /// **'Open invoices:'**
  String get openInvoices;

  /// Open source licenses menu item
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Label for order
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// Parameters label
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters;

  /// Password input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password validation error message
  ///
  /// In en, this message translates to:
  /// **'Password is required!'**
  String get passwordError;

  /// Password validation error message variant
  ///
  /// In en, this message translates to:
  /// **'Password is required!'**
  String get passwordError2;

  /// Password helper text
  ///
  /// In en, this message translates to:
  /// **'Minimum 5 characters'**
  String get passwordHelper;

  /// Password mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordMismatch;

  /// Password validation error message
  ///
  /// In en, this message translates to:
  /// **'Password should be at least 5 characters'**
  String get passwordValidationError;

  /// Label for payment
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Payment plan input label
  ///
  /// In en, this message translates to:
  /// **'Payment plan'**
  String get paymentPlan;

  /// Payment types menu item or section header
  ///
  /// In en, this message translates to:
  /// **'Payment Types'**
  String get paymentTypes;

  /// Pay within week checkbox text
  ///
  /// In en, this message translates to:
  /// **'Pay within a week'**
  String get payWithinWeek;

  /// Privacy and code of conduct menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy/Code of Conduct'**
  String get privacyCodeOfConduct;

  /// Referrer URL label
  ///
  /// In en, this message translates to:
  /// **'Referrer URL'**
  String get referrerUrl;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Register and charge button text
  ///
  /// In en, this message translates to:
  /// **'Register and charge'**
  String get registerAndCharge;

  /// Register new company link text
  ///
  /// In en, this message translates to:
  /// **'Register new company and admin'**
  String get registerNewCompanyAndAdmin;

  /// Registration dialog title
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// Request name label
  ///
  /// In en, this message translates to:
  /// **'Request name'**
  String get requestName;

  /// Request URL label
  ///
  /// In en, this message translates to:
  /// **'Request URL'**
  String get requestUrl;

  /// Restart button text
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// REST request details title
  ///
  /// In en, this message translates to:
  /// **'Rest Request Details'**
  String get restRequestDetails;

  /// Revenue and expense report menu item
  ///
  /// In en, this message translates to:
  /// **'Revenue/Expense'**
  String get revenueExpense;

  /// Running time label
  ///
  /// In en, this message translates to:
  /// **'Running time'**
  String get runningTime;

  /// Select language instruction
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// Select plan validation error message
  ///
  /// In en, this message translates to:
  /// **'Please select a plan!'**
  String get selectPlanError;

  /// Send new password dialog title
  ///
  /// In en, this message translates to:
  /// **'Send new password'**
  String get sendNewPassword;

  /// Server host label
  ///
  /// In en, this message translates to:
  /// **'Server host'**
  String get serverHost;

  /// Server IP label
  ///
  /// In en, this message translates to:
  /// **'Server IP'**
  String get serverIp;

  /// Label for shipment
  ///
  /// In en, this message translates to:
  /// **'Shipment'**
  String get shipment;

  /// Slow hit label
  ///
  /// In en, this message translates to:
  /// **'Slow hit'**
  String get slowHit;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Submit new password button text
  ///
  /// In en, this message translates to:
  /// **'Submit new password'**
  String get submitNewPassword;

  /// Subscription dialog title
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Success status text
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Label for supplier
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// Temporary password information text
  ///
  /// In en, this message translates to:
  /// **'A temporary password will be sent by email'**
  String get tempPassword;

  /// Test menu item
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// Test system text
  ///
  /// In en, this message translates to:
  /// **'Test system'**
  String get testSystem;

  /// Theme menu item
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Time periods menu item or section header
  ///
  /// In en, this message translates to:
  /// **'Time Periods'**
  String get timePeriods;

  /// Label for transaction
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// Transactions menu item or section header
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Trial period text
  ///
  /// In en, this message translates to:
  /// **'Trial period'**
  String get trialPeriod;

  /// Placeholder text for unknown values
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'update'**
  String get update;

  /// User label
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Delete user and company option text
  ///
  /// In en, this message translates to:
  /// **'Delete user and company'**
  String get userAndCompanyDelete;

  /// Username display text
  ///
  /// In en, this message translates to:
  /// **'Username: {username}'**
  String username(String username);

  /// Username or email input label
  ///
  /// In en, this message translates to:
  /// **'Username/Email'**
  String get usernameEmail;

  /// Username/email validation error message
  ///
  /// In en, this message translates to:
  /// **'Username/email is required!'**
  String get usernameEmailError;

  /// Verify password input label
  ///
  /// In en, this message translates to:
  /// **'Verify Password'**
  String get verifyPassword;

  /// Verify password validation error message
  ///
  /// In en, this message translates to:
  /// **'Verify password is required!'**
  String get verifyPasswordError;

  /// Verify password helper text
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get verifyPasswordHelper;

  /// Version display text
  ///
  /// In en, this message translates to:
  /// **'Version: {version} build: {build}'**
  String version(String version, String build);

  /// View license menu item
  ///
  /// In en, this message translates to:
  /// **'View License'**
  String get viewLicense;

  /// View readme menu item
  ///
  /// In en, this message translates to:
  /// **'View Readme'**
  String get viewReadme;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// Welcome message on home page
  ///
  /// In en, this message translates to:
  /// **'Welcome to the GrowERP business system!'**
  String get welcomeToGrowERPBusinessSystem;

  /// Yes answer text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Accounting menu item
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get accounting;

  /// Accounting dashboard menu item
  ///
  /// In en, this message translates to:
  /// **'Accounting Dashboard'**
  String get accountingDashboard;

  /// Accounting ledger menu item
  ///
  /// In en, this message translates to:
  /// **'Accounting Ledger'**
  String get accountingLedger;

  /// Accounting purchase menu item
  ///
  /// In en, this message translates to:
  /// **'Accounting Purchase'**
  String get accountingPurch;

  /// Accounting sales menu item
  ///
  /// In en, this message translates to:
  /// **'Accounting Sales'**
  String get accountingSales;

  /// Administrators label
  ///
  /// In en, this message translates to:
  /// **'Administrators'**
  String get administrators;

  /// All opportunities label
  ///
  /// In en, this message translates to:
  /// **'All Opportunities'**
  String get allOpportunities;

  /// Assets menu item
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// Catalog menu item
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// Categories menu item
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Company menu item
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// CRM menu item
  ///
  /// In en, this message translates to:
  /// **'CRM'**
  String get crm;

  /// Customers menu item
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// Employees menu item
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// Incoming invoices menu item
  ///
  /// In en, this message translates to:
  /// **'Incoming Invoices'**
  String get incomingInvoices;

  /// Incoming payments menu item
  ///
  /// In en, this message translates to:
  /// **'Incoming Payments'**
  String get incomingPayments;

  /// Incoming shipments menu item
  ///
  /// In en, this message translates to:
  /// **'Incoming Shipments'**
  String get incomingShipments;

  /// Inventory menu item
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// Leads menu item
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get leads;

  /// Ledger account menu item
  ///
  /// In en, this message translates to:
  /// **'Ledger Account'**
  String get ledgerAccnt;

  /// Ledger journals menu item
  ///
  /// In en, this message translates to:
  /// **'Ledger Journals'**
  String get ledgerJournals;

  /// Ledger transaction menu item
  ///
  /// In en, this message translates to:
  /// **'Ledger Transaction'**
  String get ledgerTransaction;

  /// Ledger tree menu item
  ///
  /// In en, this message translates to:
  /// **'Ledger Tree'**
  String get ledgerTree;

  /// My todo tasks menu item
  ///
  /// In en, this message translates to:
  /// **'My Todo Tasks'**
  String get myTodoTasks;

  /// Opportunities menu item
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get opportunities;

  /// Orders menu item
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// Organization menu item
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// Other employees label
  ///
  /// In en, this message translates to:
  /// **'Other Employees'**
  String get otherEmployees;

  /// Outgoing invoices menu item
  ///
  /// In en, this message translates to:
  /// **'Outgoing Invoices'**
  String get outgoingInvoices;

  /// Outgoing payments menu item
  ///
  /// In en, this message translates to:
  /// **'Outgoing Payments'**
  String get outgoingPayments;

  /// Outgoing shipments menu item
  ///
  /// In en, this message translates to:
  /// **'Outgoing Shipments'**
  String get outgoingShipments;

  /// Payment types menu item
  ///
  /// In en, this message translates to:
  /// **'Payment Types'**
  String get paymtTypes;

  /// Plan selection menu item
  ///
  /// In en, this message translates to:
  /// **'Plan Selection'**
  String get planSelection;

  /// Products menu item
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// Purchase orders menu item
  ///
  /// In en, this message translates to:
  /// **'Purchase Orders'**
  String get purchaseOrders;

  /// Purchase unpaid invoices label
  ///
  /// In en, this message translates to:
  /// **'Purchase Unpaid Invoices'**
  String get purchaseUnpaidInvoices;

  /// Reports menu item
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Requests menu item
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// Sales open invoices label
  ///
  /// In en, this message translates to:
  /// **'Sales Open Invoices'**
  String get salesOpenInvoices;

  /// Sales orders menu item
  ///
  /// In en, this message translates to:
  /// **'Sales Orders'**
  String get salesOrders;

  /// Set up menu item
  ///
  /// In en, this message translates to:
  /// **'Set Up'**
  String get setUp;

  /// Subscriptions menu item
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// Suppliers menu item
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// Website menu item
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Warehouse locations menu item
  ///
  /// In en, this message translates to:
  /// **'Warehouse Locations'**
  String get whLocations;

  /// Check in menu item
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// Check out menu item
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// In/out menu item
  ///
  /// In en, this message translates to:
  /// **'In/Out'**
  String get inOut;

  /// My hotel menu item
  ///
  /// In en, this message translates to:
  /// **'My Hotel'**
  String get myHotel;

  /// Reservations menu item
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// Rooms menu item
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// Room types menu item
  ///
  /// In en, this message translates to:
  /// **'Room Types'**
  String get roomTypes;

  /// Tasks menu item
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// My opportunities menu item
  ///
  /// In en, this message translates to:
  /// **'My Opportunities'**
  String get myOpportunities;

  /// Clients menu item
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// Staff menu item
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// Applications menu item
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// REST requests menu item
  ///
  /// In en, this message translates to:
  /// **'REST Requests'**
  String get restRequests;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
