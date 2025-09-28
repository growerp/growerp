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

  /// Login form header text
  ///
  /// In en, this message translates to:
  /// **'Login with existing username'**
  String get loginWithExistingUserName;

  /// Header for password creation form
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createPassword;

  /// Username display with placeholder
  ///
  /// In en, this message translates to:
  /// **'Username: {username}'**
  String username(String username);

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password requirements helper text
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, including alpha, number & special character, no previous password.'**
  String get passwordHelper;

  /// Error message for empty password field
  ///
  /// In en, this message translates to:
  /// **'Please enter first password?'**
  String get passwordError;

  /// Error message for invalid password format
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, including alpha, number & special character.'**
  String get passwordValidationError;

  /// Password confirmation field label
  ///
  /// In en, this message translates to:
  /// **'Verify Password'**
  String get verifyPassword;

  /// Helper text for password confirmation field
  ///
  /// In en, this message translates to:
  /// **'Enter the new password again.'**
  String get verifyPasswordHelper;

  /// Error message for empty password confirmation field
  ///
  /// In en, this message translates to:
  /// **'Enter password again to verify?'**
  String get verifyPasswordError;

  /// Error message for mismatched password confirmation
  ///
  /// In en, this message translates to:
  /// **'Password is not matching'**
  String get passwordMismatch;

  /// Submit button text for new password form
  ///
  /// In en, this message translates to:
  /// **'Submit new Password'**
  String get submitNewPassword;

  /// Registration completion form header
  ///
  /// In en, this message translates to:
  /// **'Complete your registration'**
  String get completeRegistration;

  /// Welcome greeting message
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// Helper text for company and currency form fields
  ///
  /// In en, this message translates to:
  /// **'please enter both the company name\nand currency for the new company'**
  String get enterCompanyAndCurrency;

  /// Helper text for optional company name field
  ///
  /// In en, this message translates to:
  /// **'please enter optionally a company name you work for.'**
  String get enterCompanyName;

  /// Business company name field label
  ///
  /// In en, this message translates to:
  /// **'Business Company name'**
  String get businessCompanyName;

  /// Error message for empty business name field
  ///
  /// In en, this message translates to:
  /// **'Please enter business name(\"Private\" for Private person)'**
  String get businessNameError;

  /// Currency field label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Error message for empty currency field
  ///
  /// In en, this message translates to:
  /// **'Currency field required!'**
  String get currencyError;

  /// Checkbox label for generating demo data
  ///
  /// In en, this message translates to:
  /// **'Generate demo data'**
  String get generateDemoData;

  /// Demo data label or header
  ///
  /// In en, this message translates to:
  /// **'DemoData'**
  String get demoData;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Username or email field label
  ///
  /// In en, this message translates to:
  /// **'Username/Email'**
  String get usernameEmail;

  /// Error message for empty username/email field
  ///
  /// In en, this message translates to:
  /// **'Please enter username or email?'**
  String get usernameEmailError;

  /// Error message for empty password field on login
  ///
  /// In en, this message translates to:
  /// **'Please enter your password?'**
  String get passwordError2;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'forgot/change password?'**
  String get forgotPassword;

  /// Subscription section header
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Message showing the user's current payment method
  ///
  /// In en, this message translates to:
  /// **'Your current payment method:\n{ccDescription}'**
  String currentPaymentMethod(String ccDescription);

  /// Trial period information message
  ///
  /// In en, this message translates to:
  /// **'You have a trial period for 2 weeks,\nWe will only charge if you not cancel\nbefore that time'**
  String get trialPeriod;

  /// Test system notification message
  ///
  /// In en, this message translates to:
  /// **'This is a Test system\nso this credit Card will always be approved'**
  String get testSystem;

  /// Payment plan section header
  ///
  /// In en, this message translates to:
  /// **'Payment Plan'**
  String get paymentPlan;

  /// Error message for plan selection
  ///
  /// In en, this message translates to:
  /// **'Please select a single plan'**
  String get selectPlanError;

  /// Credit card information section header
  ///
  /// In en, this message translates to:
  /// **'Credit card information'**
  String get creditCardInfo;

  /// Instructions for entering credit card details
  ///
  /// In en, this message translates to:
  /// **'Enter your credit card details'**
  String get creditCardDetails;

  /// Credit card number field label
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// Placeholder text for credit card number
  ///
  /// In en, this message translates to:
  /// **'XXXX XXXX XXXX XXXX'**
  String get numberHint;

  /// Credit card expiry date field label
  ///
  /// In en, this message translates to:
  /// **'Expiry month/year'**
  String get expiryDate;

  /// Placeholder text for credit card expiry date
  ///
  /// In en, this message translates to:
  /// **'XX/XX'**
  String get expiryDateHint;

  /// Credit card CVV code field label
  ///
  /// In en, this message translates to:
  /// **'CVV Code'**
  String get cvvCode;

  /// Placeholder text for CVV code
  ///
  /// In en, this message translates to:
  /// **'XXX'**
  String get cvvHint;

  /// Name on credit card field label
  ///
  /// In en, this message translates to:
  /// **'Name on Card'**
  String get nameOnCard;

  /// Payment deadline notification
  ///
  /// In en, this message translates to:
  /// **'Pay within one week'**
  String get payWithinWeek;

  /// Registration and charging timeline information
  ///
  /// In en, this message translates to:
  /// **'Register and charge in 2 weeks'**
  String get registerAndCharge;

  /// Button text for sending new password via email
  ///
  /// In en, this message translates to:
  /// **'Send new Password by email'**
  String get sendNewPassword;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get email;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// Warning message about account deletion consequences
  ///
  /// In en, this message translates to:
  /// **'Please note you will be blocked using the system.\nThis cannot be undone!'**
  String get deleteWarning;

  /// Option to delete only the user account
  ///
  /// In en, this message translates to:
  /// **'Only User delete'**
  String get onlyUserDelete;

  /// Option to delete both user and company
  ///
  /// In en, this message translates to:
  /// **'User AND Company delete'**
  String get userAndCompanyDelete;

  /// Button text for self-deletion
  ///
  /// In en, this message translates to:
  /// **'Delete yourself'**
  String get deleteYourself;

  /// Confirmation text for deleting user and optional company
  ///
  /// In en, this message translates to:
  /// **'Delete yourself and opt. company?'**
  String get deleteYourselfAndCompany;

  /// Registration form header
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Error message for empty first name field
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name?'**
  String get firstNameError;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Error message for empty last name field
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name?'**
  String get lastNameError;

  /// Information about temporary password delivery
  ///
  /// In en, this message translates to:
  /// **'A temporary password will be send by email'**
  String get tempPassword;

  /// Email address field label
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// Error message for empty email address field
  ///
  /// In en, this message translates to:
  /// **'Please enter Email address?'**
  String get emailAddressError;

  /// Error message for invalid email format
  ///
  /// In en, this message translates to:
  /// **'This is not a valid email'**
  String get emailAddressError2;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// About GrowERP section header
  ///
  /// In en, this message translates to:
  /// **'About GrowERP'**
  String get aboutGrowERP;

  /// About page header showing the app name
  ///
  /// In en, this message translates to:
  /// **'About GrowERP and this {appName} app'**
  String aboutApp(String appName);

  /// Version information display
  ///
  /// In en, this message translates to:
  /// **'Version {version}, build #{build}'**
  String version(String version, String build);

  /// Copyright notice with year
  ///
  /// In en, this message translates to:
  /// **'© GrowERP, {year}'**
  String copyright(int year);

  /// Button text to view readme file
  ///
  /// In en, this message translates to:
  /// **'View Readme'**
  String get viewReadme;

  /// Button text to view license information
  ///
  /// In en, this message translates to:
  /// **'View License'**
  String get viewLicense;

  /// Contributing section header or button text
  ///
  /// In en, this message translates to:
  /// **'Contributing'**
  String get contributing;

  /// Privacy and code of conduct section header
  ///
  /// In en, this message translates to:
  /// **'Privacy, Code of conduct'**
  String get privacyCodeOfConduct;

  /// Open source licenses section header
  ///
  /// In en, this message translates to:
  /// **'Open source Licenses'**
  String get openSourceLicenses;

  /// Instructions for entering backend URL
  ///
  /// In en, this message translates to:
  /// **'Enter a backend && chat url in the form of: xxx.yyy.zzz'**
  String get enterBackendUrl;

  /// Backend server configuration label
  ///
  /// In en, this message translates to:
  /// **'Backend server:'**
  String get backendServer;

  /// Generic required field error message
  ///
  /// In en, this message translates to:
  /// **'field required!'**
  String get fieldRequired;

  /// Chat server configuration label
  ///
  /// In en, this message translates to:
  /// **'Chat server:'**
  String get chatServer;

  /// Company party ID configuration label
  ///
  /// In en, this message translates to:
  /// **'partyId of main company:'**
  String get companyPartyId;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Restart button text
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Main navigation or section header
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// Message when user has no access to any options
  ///
  /// In en, this message translates to:
  /// **'No Access to any option'**
  String get noAccess;

  /// Add new item button text
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// Chat menu item or button text
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Navigation button to go to home screen
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// Test label or placeholder text
  ///
  /// In en, this message translates to:
  /// **'test'**
  String get test;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'error: should not arrive here'**
  String get error;

  /// Message when user has no access to current section
  ///
  /// In en, this message translates to:
  /// **'No access to any option here, '**
  String get noAccessHere;

  /// Message when no REST requests are available
  ///
  /// In en, this message translates to:
  /// **'No REST requests found'**
  String get noRestRequests;

  /// Error message when REST requests fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load REST requests!'**
  String get cannotLoadRestRequests;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Header for REST request details screen
  ///
  /// In en, this message translates to:
  /// **'REST Request Details'**
  String get restRequestDetails;

  /// Date and time field label
  ///
  /// In en, this message translates to:
  /// **'Date/Time'**
  String get dateTime;

  /// Placeholder text for unknown values
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// User label or menu item
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Abbreviation for Not Available
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// Login name field label
  ///
  /// In en, this message translates to:
  /// **'Login Name'**
  String get loginName;

  /// Request name field label
  ///
  /// In en, this message translates to:
  /// **'Request Name'**
  String get requestName;

  /// Server IP address field label
  ///
  /// In en, this message translates to:
  /// **'Server IP'**
  String get serverIp;

  /// Server hostname field label
  ///
  /// In en, this message translates to:
  /// **'Server Host'**
  String get serverHost;

  /// Request running time field label
  ///
  /// In en, this message translates to:
  /// **'Running Time'**
  String get runningTime;

  /// Milliseconds unit abbreviation
  ///
  /// In en, this message translates to:
  /// **' ms'**
  String get ms;

  /// Status field label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Success confirmation message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Label for slow performance indicator
  ///
  /// In en, this message translates to:
  /// **'Slow Hit'**
  String get slowHit;

  /// Yes confirmation button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No confirmation button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Error message field label
  ///
  /// In en, this message translates to:
  /// **'Error Message:'**
  String get errorMessage;

  /// Request URL field label
  ///
  /// In en, this message translates to:
  /// **'Request URL:'**
  String get requestUrl;

  /// Referrer URL field label
  ///
  /// In en, this message translates to:
  /// **'Referrer URL:'**
  String get referrerUrl;

  /// Parameters field label
  ///
  /// In en, this message translates to:
  /// **'Parameters:'**
  String get parameters;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Main welcome message for the GrowERP system
  ///
  /// In en, this message translates to:
  /// **'Welcome to The GrowERP Business System'**
  String get welcomeToGrowERPBusinessSystem;

  /// Language selection dropdown or button text
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Registration form header for new company and admin
  ///
  /// In en, this message translates to:
  /// **'Register new Company and Administrator'**
  String get registerNewCompanyAndAdmin;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Label for customer
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Label for supplier
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// Partial validation message indicating minimum requirement
  ///
  /// In en, this message translates to:
  /// **'and at least one '**
  String get andAtLeastOne;

  /// Validation message indicating a required item
  ///
  /// In en, this message translates to:
  /// **'item is required'**
  String get itemIsRequired;
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
