/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'company_test.dart' as company;
import 'category_test.dart' as category;
import 'product_test.dart' as product;
import 'asset_test.dart' as asset;
import 'user_test.dart' as user;
import 'opportunity_test.dart' as opportunity;
import 'payment_sales_test.dart' as sales_payment;
import 'payment_purchase_test.dart' as purchase_payment;
import 'invoice_sales_test.dart' as sales_invoice;
import 'invoice_purchase_test.dart' as purchase_invoice;
import 'roundtrip.dart' as purchase_sales;
import 'room_rental_test.dart' as room_rental;
import 'chat_test.dart' as chat;
import 'website_test.dart' as website;

void main() {
  company.main();
  category.main();
  product.main();
  asset.main();
  user.main();
  opportunity.main();
  sales_payment.main();
  purchase_payment.main();
  sales_invoice.main();
  purchase_invoice.main();
  purchase_sales.main();
  room_rental.main();
  website.main();
  //  chat.main();
}
