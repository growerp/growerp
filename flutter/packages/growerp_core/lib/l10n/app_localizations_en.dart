// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginWithExistingUserName => 'Login with existing username';

  @override
  String get createPassword => 'Create New Password';

  @override
  String username(String username) {
    return 'Username: $username';
  }

  @override
  String get password => 'Password';

  @override
  String get passwordHelper =>
      'At least 8 characters, including alpha, number & special character, no previous password.';

  @override
  String get passwordError => 'Please enter first password?';

  @override
  String get passwordValidationError =>
      'At least 8 characters, including alpha, number & special character.';

  @override
  String get verifyPassword => 'Verify Password';

  @override
  String get verifyPasswordHelper => 'Enter the new password again.';

  @override
  String get verifyPasswordError => 'Enter password again to verify?';

  @override
  String get passwordMismatch => 'Password is not matching';

  @override
  String get submitNewPassword => 'Submit new Password';

  @override
  String get completeRegistration => 'Complete your registration';

  @override
  String get welcome => 'Welcome!';

  @override
  String get enterCompanyAndCurrency =>
      'please enter both the company name\nand currency for the new company';

  @override
  String get enterCompanyName =>
      'please enter optionally a company name you work for.';

  @override
  String get businessCompanyName => 'Business Company name';

  @override
  String get businessNameError =>
      'Please enter business name(\"Private\" for Private person)';

  @override
  String get currency => 'Currency';

  @override
  String get currencyError => 'Currency field required!';

  @override
  String get generateDemoData => 'Generate demo data';

  @override
  String get demoData => 'DemoData';

  @override
  String get continueButton => 'Continue';

  @override
  String get usernameEmail => 'Username/Email';

  @override
  String get usernameEmailError => 'Please enter username or email?';

  @override
  String get passwordError2 => 'Please enter your password?';

  @override
  String get login => 'Login';

  @override
  String get forgotPassword => 'forgot/change password?';

  @override
  String get subscription => 'Subscription';

  @override
  String currentPaymentMethod(String ccDescription) {
    return 'Your current payment method:\n$ccDescription';
  }

  @override
  String get trialPeriod =>
      'You have a trial period for 2 weeks,\nWe will only charge if you not cancel\nbefore that time';

  @override
  String get testSystem =>
      'This is a Test system\nso this credit Card will always be approved';

  @override
  String get paymentPlan => 'Payment Plan';

  @override
  String get selectPlanError => 'Please select a single plan';

  @override
  String get creditCardInfo => 'Credit card information';

  @override
  String get creditCardDetails => 'Enter your credit card details';

  @override
  String get number => 'Number';

  @override
  String get numberHint => 'XXXX XXXX XXXX XXXX';

  @override
  String get expiryDate => 'Expiry month/year';

  @override
  String get expiryDateHint => 'XX/XX';

  @override
  String get cvvCode => 'CVV Code';

  @override
  String get cvvHint => 'XXX';

  @override
  String get nameOnCard => 'Name on Card';

  @override
  String get payWithinWeek => 'Pay within one week';

  @override
  String get registerAndCharge => 'Register and charge in 2 weeks';

  @override
  String get sendNewPassword => 'Send new Password by email';

  @override
  String get email => 'Email:';

  @override
  String get ok => 'Ok';

  @override
  String get deleteWarning =>
      'Please note you will be blocked using the system.\nThis cannot be undone!';

  @override
  String get onlyUserDelete => 'Only User delete';

  @override
  String get userAndCompanyDelete => 'User AND Company delete';

  @override
  String get deleteYourself => 'Delete yourself';

  @override
  String get deleteYourselfAndCompany => 'Delete yourself and opt. company?';

  @override
  String get registration => 'Registration';

  @override
  String get firstName => 'First Name';

  @override
  String get firstNameError => 'Please enter your first name?';

  @override
  String get lastName => 'Last Name';

  @override
  String get lastNameError => 'Please enter your last name?';

  @override
  String get tempPassword => 'A temporary password will be send by email';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressError => 'Please enter Email address?';

  @override
  String get emailAddressError2 => 'This is not a valid email';

  @override
  String get register => 'Register';

  @override
  String get aboutGrowERP => 'About GrowERP';

  @override
  String aboutApp(String appName) {
    return 'About GrowERP and this $appName app';
  }

  @override
  String version(String version, String build) {
    return 'Version $version, build #$build';
  }

  @override
  String copyright(int year) {
    return '© GrowERP, $year';
  }

  @override
  String get viewReadme => 'View Readme';

  @override
  String get viewLicense => 'View License';

  @override
  String get contributing => 'Contributing';

  @override
  String get privacyCodeOfConduct => 'Privacy, Code of conduct';

  @override
  String get openSourceLicenses => 'Open source Licenses';

  @override
  String get enterBackendUrl =>
      'Enter a backend && chat url in the form of: xxx.yyy.zzz';

  @override
  String get backendServer => 'Backend server:';

  @override
  String get fieldRequired => 'field required!';

  @override
  String get chatServer => 'Chat server:';

  @override
  String get companyPartyId => 'partyId of main company:';

  @override
  String get cancel => 'Cancel';

  @override
  String get restart => 'Restart';

  @override
  String get main => 'Main';

  @override
  String get noAccess => 'No Access to any option';

  @override
  String get addNew => 'Add New';

  @override
  String get chat => 'Chat';

  @override
  String get goHome => 'Go Home';

  @override
  String get test => 'test';

  @override
  String get theme => 'Theme';

  @override
  String get error => 'error: should not arrive here';

  @override
  String get noAccessHere => 'No access to any option here, ';

  @override
  String get noRestRequests => 'No REST requests found';

  @override
  String get cannotLoadRestRequests => 'Could not load REST requests!';

  @override
  String get refresh => 'Refresh';

  @override
  String get restRequestDetails => 'REST Request Details';

  @override
  String get dateTime => 'Date/Time';

  @override
  String get unknown => 'Unknown';

  @override
  String get user => 'User';

  @override
  String get notAvailable => 'N/A';

  @override
  String get loginName => 'Login Name';

  @override
  String get requestName => 'Request Name';

  @override
  String get serverIp => 'Server IP';

  @override
  String get serverHost => 'Server Host';

  @override
  String get runningTime => 'Running Time';

  @override
  String get ms => ' ms';

  @override
  String get status => 'Status';

  @override
  String get success => 'Success';

  @override
  String get slowHit => 'Slow Hit';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get errorMessage => 'Error Message:';

  @override
  String get requestUrl => 'Request URL:';

  @override
  String get referrerUrl => 'Referrer URL:';

  @override
  String get parameters => 'Parameters:';

  @override
  String get logout => 'Logout';

  @override
  String get welcomeToGrowERPBusinessSystem =>
      'Welcome to The GrowERP Business System';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get registerNewCompanyAndAdmin =>
      'Register new Company and Administrator';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get customer => 'Customer';

  @override
  String get supplier => 'Supplier';

  @override
  String get andAtLeastOne => 'and at least one ';

  @override
  String get itemIsRequired => 'item is required';
}
