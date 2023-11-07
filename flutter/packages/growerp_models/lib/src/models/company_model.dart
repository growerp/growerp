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

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import '../create_csv_row.dart';
import '../json_converters.dart';
import 'models.dart';

part 'company_model.freezed.dart';
part 'company_model.g.dart';

@freezed
class Company with _$Company {
  Company._();
  factory Company({
    String? partyId,
    String? pseudoId,
    @RoleConverter() Role? role,
    String? name,
    String? email,
    String? telephoneNr,
    Currency? currency,
    @Uint8ListConverter() Uint8List? image,
    Address? address,
    PaymentMethod? paymentMethod,
    Decimal? vatPerc,
    Decimal? salesPerc,
    @Default([]) List<User> employees,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json["company"] ?? json);

  @override
  String toString() => 'Company name: $name[$partyId] '
      'Curr: ${currency?.currencyId} '
      'imgSize: ${image?.length}'
      '#Empl: ${employees.length}';
}

String companyCsvFormat =
    'System Id, PseudoId, Role, Company Name*, Email, Telephone, Currency id,'
    'Image,Postal Address 1, Address 2, Postal Code, City, Province, Country '
    'Credit Card Description, Number, Type, Expire month, Year, '
    'Vat perc, Sales Perc\r\n';
int companyCsvLength = companyCsvFormat.split(',').length;

List<Company> CsvToCompanies(String csvFile) {
  List<Company> companies = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    companies.add(Company(
      partyId: row[0],
      pseudoId: row[1],
      role: Role.getByValue(row[2]),
      name: row[3],
      email: row[4].contains('@example.com') // avoid duplicated emails
          ? (Random().nextInt(1000).toString() + row[4])
          : row[4],
      telephoneNr: row[5],
      currency: Currency(currencyId: row[6]),
      image: row[7].isNotEmpty ? base64.decode(row[6]) : null,
      address: Address(
          address1: row[8],
          address2: row[9],
          postalCode: row[10],
          city: row[11],
          province: row[12],
          country: row[13]),
      paymentMethod: PaymentMethod(
          ccDescription: row[14],
          creditCardType: CreditCardType.getByValue(row[15]),
          expireMonth: row[16],
          expireYear: row[17]),
      vatPerc: row[18] != '' ? Decimal.parse(row[18]) : null,
      salesPerc: row[19] != '' ? Decimal.parse(row[19]) : null,
    ));
  }

  return companies;
}

String CsvFromCompanies(List<Company> companies) {
  var csv = [companyCsvFormat];
  for (Company company in companies) {
    csv.add(createCsvRow([
      company.partyId ?? '',
      company.pseudoId ?? '',
      company.role.toString(),
      company.name ?? '',
      company.email ?? '',
      company.currency?.currencyId ?? '',
      company.image != null ? base64.encode(company.image!) : '',
      company.address?.address1 ?? '',
      company.address?.address2 ?? '',
      company.address?.postalCode ?? '',
      company.address?.city ?? '',
      company.address?.province ?? '',
      company.address?.country ?? '',
      company.paymentMethod?.ccDescription ?? '',
      company.paymentMethod?.creditCardType!.value ?? '',
      company.paymentMethod?.creditCardNumber ?? '',
      company.paymentMethod?.expireMonth ?? '',
      company.paymentMethod?.expireYear ?? '',
      company.vatPerc.toString(),
      company.salesPerc.toString(),
    ], companyCsvLength));
  }
  return csv.join();
}
