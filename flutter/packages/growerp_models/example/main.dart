import 'package:growerp_models/growerp_models.dart';

/// Demonstrates decoding a GrowERP REST response into a typed model and
/// serializing it back to JSON, using the GL account model as an example.
void main() {
  final json = {
    'glAccount': {
      'glAccountId': '110000',
      'accountCode': '110000',
      'accountName': 'Cash',
      'isDebit': true,
    },
  };

  final account = GlAccount.fromJson(json);
  // ignore: avoid_print
  print('${account.accountCode}: ${account.accountName}');

  final backToJson = account.toJson();
  // ignore: avoid_print
  print(backToJson);
}
