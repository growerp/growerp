export 'package:growerp_models/testing.dart';

import 'package:growerp_models/growerp_models.dart';

const applicationId = 'AppAdmin';

final category1 = Category(categoryId: 'C1', categoryName: 'Fruit');
final category2 = Category(categoryId: 'C2', categoryName: 'Vegetables');

const product1 = Product(productId: 'P1', productName: 'Apple');
const product2 = Product(productId: 'P2', productName: 'Pear');
final kgUom = Uom(uomId: 'WT_kg', uomTypeId: 'UT_WEIGHT_MEASURE');

const productUomTypes = [
  'UT_WEIGHT_MEASURE',
  'UT_VOLUME_DRY_MEAS',
  'UT_VOLUME_LIQ_MEAS',
  'UT_TIME_FREQ_MEASURE',
  'UT_LENGTH_MEASURE',
  'UT_OTHER_MEASURE',
];

final subscription1 = Subscription(subscriptionId: 'S1', pseudoId: 'sub1');
final subscription2 = Subscription(subscriptionId: 'S2', pseudoId: 'sub2');
