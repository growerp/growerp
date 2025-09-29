// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String aboutApp(String appName) {
    return 'About $appName';
  }

  @override
  String get aboutGrowERP => 'About GrowERP';

  @override
  String get accounts => 'Accounts';

  @override
  String get addNew => 'Add new';

  @override
  String get andAtLeastOne => 'and at least one ';

  @override
  String get backendServer => 'Backend Server';

  @override
  String get balanceSheet => 'Balance Sheet';

  @override
  String get balanceSummary => 'Balance Summary';

  @override
  String get businessCompanyName => 'Business company name required!';

  @override
  String get businessNameError => 'Business name is required!';

  @override
  String get cancel => 'Cancel';

  @override
  String get cannotLoadRestRequests => 'Cannot load rest requests!';

  @override
  String get chat => 'Chat';

  @override
  String get chatServer => 'Chat Server';

  @override
  String get completeRegistration => 'Complete Registration';

  @override
  String get companyPartyId => 'Company Party Id';

  @override
  String get continueButton => 'Continue';

  @override
  String get contributing => 'Contributing';

  @override
  String copyright(String year) {
    return '© $year GrowERP.com';
  }

  @override
  String get create => 'Create';

  @override
  String get createPassword => 'Create password';

  @override
  String get creditCardDetails => 'Credit card details';

  @override
  String get creditCardInfo => 'Credit card info';

  @override
  String get currency => 'Currency';

  @override
  String get currencyError => 'Currency is required!';

  @override
  String currentPaymentMethod(String method) {
    return 'Current payment method: $method';
  }

  @override
  String get customer => 'Customer';

  @override
  String get cvvCode => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get dateTime => 'Date/Time';

  @override
  String get deleteWarning => 'Delete Warning';

  @override
  String get deleteYourself => 'Delete yourself';

  @override
  String get deleteYourselfAndCompany => 'Delete yourself and company';

  @override
  String get demoData => 'Demo data';

  @override
  String get email => 'Email';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailAddressError => 'Email address is required!';

  @override
  String get emailAddressError2 => 'Email address format incorrect!';

  @override
  String get enterBackendUrl => 'Enter backend URL';

  @override
  String get enterCompanyAndCurrency =>
      'Please enter your company name and currency';

  @override
  String get enterCompanyName => 'Enter company name';

  @override
  String get error => 'Error';

  @override
  String get errorMessage => 'Error message';

  @override
  String get expiryDate => 'MM/YY';

  @override
  String get expiryDateHint => '12/25';

  @override
  String get fieldRequired => 'Field is required!';

  @override
  String get firstName => 'First Name';

  @override
  String get firstNameError => 'First name is required!';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get generateDemoData => 'Generate demo data?';

  @override
  String get goHome => 'Go Home';

  @override
  String get invoice => 'Invoice';

  @override
  String get itemIsRequired => 'item is required';

  @override
  String get itemTypes => 'Item Types';

  @override
  String get journal => 'Journal';

  @override
  String get lastName => 'Last Name';

  @override
  String get lastNameError => 'Last name is required!';

  @override
  String get login => 'Login';

  @override
  String get loginName => 'Login name';

  @override
  String get loginWithExistingUserName => 'Login with Existing user name';

  @override
  String get logout => 'Logout';

  @override
  String get main => 'Main';

  @override
  String get mainDashboard => 'Main Dashboard';

  @override
  String get ms => 'ms';

  @override
  String get nameOnCard => 'Name on card';

  @override
  String get no => 'No';

  @override
  String get noAccess => 'No access to this page!';

  @override
  String get noAccessHere => 'No Access Here!';

  @override
  String get noRestRequests => 'No REST requests found...';

  @override
  String get notAvailable => 'Not available';

  @override
  String get number => 'Number';

  @override
  String get numberHint => '1234 5678 9012 3456';

  @override
  String get ok => 'OK';

  @override
  String get onlyUserDelete => 'Only delete user, not company';

  @override
  String get openInvoices => 'Open invoices:';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get order => 'Order';

  @override
  String get parameters => 'Parameters';

  @override
  String get password => 'Password';

  @override
  String get passwordError => 'Password is required!';

  @override
  String get passwordError2 => 'Password is required!';

  @override
  String get passwordHelper => 'Minimum 5 characters';

  @override
  String get passwordMismatch => 'Passwords do not match!';

  @override
  String get passwordValidationError =>
      'Password should be at least 5 characters';

  @override
  String get payment => 'Payment';

  @override
  String get paymentPlan => 'Payment plan';

  @override
  String get paymentTypes => 'Payment Types';

  @override
  String get payWithinWeek => 'Pay within a week';

  @override
  String get privacyCodeOfConduct => 'Privacy/Code of Conduct';

  @override
  String get referrerUrl => 'Referrer URL';

  @override
  String get refresh => 'Refresh';

  @override
  String get register => 'Register';

  @override
  String get registerAndCharge => 'Register and charge';

  @override
  String get registerNewCompanyAndAdmin => 'Register new company and admin';

  @override
  String get registration => 'Registration';

  @override
  String get requestName => 'Request name';

  @override
  String get requestUrl => 'Request URL';

  @override
  String get restart => 'Restart';

  @override
  String get restRequestDetails => 'Rest Request Details';

  @override
  String get revenueExpense => 'Revenue/Expense';

  @override
  String get runningTime => 'Running time';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get selectPlanError => 'Please select a plan!';

  @override
  String get sendNewPassword => 'Send new password';

  @override
  String get serverHost => 'Server host';

  @override
  String get serverIp => 'Server IP';

  @override
  String get shipment => 'Shipment';

  @override
  String get slowHit => 'Slow hit';

  @override
  String get status => 'Status';

  @override
  String get submitNewPassword => 'Submit new password';

  @override
  String get subscription => 'Subscription';

  @override
  String get success => 'Success';

  @override
  String get supplier => 'Supplier';

  @override
  String get tempPassword => 'A temporary password will be sent by email';

  @override
  String get test => 'Test';

  @override
  String get testSystem => 'Test system';

  @override
  String get theme => 'Theme';

  @override
  String get timePeriods => 'Time Periods';

  @override
  String get transaction => 'Transaction';

  @override
  String get transactions => 'Transactions';

  @override
  String get trialPeriod => 'Trial period';

  @override
  String get unknown => 'Unknown';

  @override
  String get update => 'update';

  @override
  String get user => 'User';

  @override
  String get userAndCompanyDelete => 'Delete user and company';

  @override
  String username(String username) {
    return 'Username: $username';
  }

  @override
  String get usernameEmail => 'Username/Email';

  @override
  String get usernameEmailError => 'Username/email is required!';

  @override
  String get verifyPassword => 'Verify Password';

  @override
  String get verifyPasswordError => 'Verify password is required!';

  @override
  String get verifyPasswordHelper => 'Re-enter password';

  @override
  String version(String version, String build) {
    return 'Version: $version build: $build';
  }

  @override
  String get viewLicense => 'View License';

  @override
  String get viewReadme => 'View Readme';

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeToGrowERPBusinessSystem =>
      'Welcome to the GrowERP business system!';

  @override
  String get yes => 'Yes';

  @override
  String get about => 'About';

  @override
  String get accounting => 'Accounting';

  @override
  String get accountingDashboard => 'Accounting Dashboard';

  @override
  String get accountingLedger => 'Accounting Ledger';

  @override
  String get accountingPurch => 'Accounting Purchase';

  @override
  String get accountingSales => 'Accounting Sales';

  @override
  String get administrators => 'Administrators';

  @override
  String get allOpportunities => 'All Opportunities';

  @override
  String get assets => 'Assets';

  @override
  String get catalog => 'Catalog';

  @override
  String get categories => 'Categories';

  @override
  String get company => 'Company';

  @override
  String get crm => 'CRM';

  @override
  String get customers => 'Customers';

  @override
  String get employees => 'Employees';

  @override
  String get incomingInvoices => 'Incoming Invoices';

  @override
  String get incomingPayments => 'Incoming Payments';

  @override
  String get incomingShipments => 'Incoming Shipments';

  @override
  String get inventory => 'Inventory';

  @override
  String get leads => 'Leads';

  @override
  String get ledgerAccnt => 'Ledger Account';

  @override
  String get ledgerJournals => 'Ledger Journals';

  @override
  String get ledgerTransaction => 'Ledger Transaction';

  @override
  String get ledgerTree => 'Ledger Tree';

  @override
  String get myTodoTasks => 'My Todo Tasks';

  @override
  String get opportunities => 'Opportunities';

  @override
  String get orders => 'Orders';

  @override
  String get organization => 'Organization';

  @override
  String get otherEmployees => 'Other Employees';

  @override
  String get outgoingInvoices => 'Outgoing Invoices';

  @override
  String get outgoingPayments => 'Outgoing Payments';

  @override
  String get outgoingShipments => 'Outgoing Shipments';

  @override
  String get paymtTypes => 'Payment Types';

  @override
  String get planSelection => 'Plan Selection';

  @override
  String get products => 'Products';

  @override
  String get purchaseOrders => 'Purchase Orders';

  @override
  String get purchaseUnpaidInvoices => 'Purchase Unpaid Invoices';

  @override
  String get reports => 'Reports';

  @override
  String get requests => 'Requests';

  @override
  String get salesOpenInvoices => 'Sales Open Invoices';

  @override
  String get salesOrders => 'Sales Orders';

  @override
  String get setUp => 'Set Up';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get website => 'Website';

  @override
  String get whLocations => 'Warehouse Locations';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String get inOut => 'In/Out';

  @override
  String get myHotel => 'My Hotel';

  @override
  String get reservations => 'Reservations';

  @override
  String get rooms => 'Rooms';

  @override
  String get roomTypes => 'Room Types';

  @override
  String get tasks => 'Tasks';

  @override
  String get myOpportunities => 'My Opportunities';

  @override
  String get clients => 'Clients';

  @override
  String get staff => 'Staff';

  @override
  String get applications => 'Applications';

  @override
  String get restRequests => 'REST Requests';
}
