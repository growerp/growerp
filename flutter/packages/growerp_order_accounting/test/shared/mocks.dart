export 'package:growerp_models/testing.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

const applicationId = 'AppAdmin';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

final order1 = FinDoc(
  docType: FinDocType.order,
  orderId: 'O1',
  pseudoId: 'order1',
);
final order2 = FinDoc(
  docType: FinDocType.order,
  orderId: 'O2',
  pseudoId: 'order2',
);
final payment1 = FinDoc(
  docType: FinDocType.payment,
  paymentId: 'P1',
  pseudoId: 'pay1',
);

final itemType1 = ItemType(
  itemTypeId: 'ItemProduct',
  direction: 'O',
  itemTypeName: 'Product',
  accountCode: '4000',
  accountName: 'Sales',
);
final itemType2 = ItemType(
  itemTypeId: 'ItemShipping',
  direction: 'O',
  itemTypeName: 'Shipping',
);
final paymentType1 = PaymentType(
  paymentTypeId: 'PiCash',
  isPayable: false,
  paymentTypeName: 'Cash',
  accountCode: '1000',
);

class MockFinDocBloc extends MockBloc<FinDocEvent, FinDocState>
    implements FinDocBloc {}
