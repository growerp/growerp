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

import 'payment_sales_test.dart' as sales_payment;
import 'payment_purchase_test.dart' as purchase_payment;
import 'invoice_sales_test.dart' as sales_invoice;
import 'invoice_purchase_test.dart' as purchase_invoice;
import 'room_rental_test.dart' as room_rental;

void main() {
  sales_payment.main();
  purchase_payment.main();
  sales_invoice.main();
  purchase_invoice.main();
  room_rental.main();
}
