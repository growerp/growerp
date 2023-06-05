import 'core_localizations.dart';

/// The translations for Thai (`th`).
class CoreLocalizationsTh extends CoreLocalizations {
  CoreLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get addNew => 'Add new';

  @override
  String get andAtLeastOne => 'and at least one ';

  @override
  String get create => 'Create';

  @override
  String get customer => 'Customer';

  @override
  String get invoice => 'Invoice';

  @override
  String get itemIsRequired => 'item is required';

  @override
  String get loginWithExistingUserName => 'Login with Existing user name';

  @override
  String get order => 'Order';

  @override
  String get payment => 'Payment';

  @override
  String get shipment => 'Shipment';

  @override
  String get supplier => 'Supplier';

  @override
  String get transaction => 'Transaction';

  @override
  String get unknown => 'Unknown';

  @override
  String update(Object num) {
    return 'update $num';
  }
}
