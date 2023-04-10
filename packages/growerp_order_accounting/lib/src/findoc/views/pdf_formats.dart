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
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:growerp_core/growerp_core.dart';

class PdfFormats {
  //
  // financial document, ivoice, payment, order etc....
  static Future<Uint8List> finDocPdf(
      PdfPageFormat format, Company company, FinDoc finDoc) async {
    final pdf = pw.Document();

    pdf.addPage(MultiPage(
      build: (context) => [
        buildHeader(company, finDoc),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(finDoc),
        buildFinDoc(finDoc),
        Divider(),
        buildTotal(finDoc),
      ],
      footer: (context) => buildFooter(company, finDoc),
    ));

    return pdf.save();
  }

  static Widget buildHeader(Company company, FinDoc finDoc) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * PdfPageFormat.cm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildSupplierAddress(company),
              Container(
                height: 50,
                width: 50,
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: finDoc.id()!,
                ),
              ),
            ],
          ),
          SizedBox(height: 1 * PdfPageFormat.cm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildCustomerAddress(finDoc.otherUser!),
              buildFinDocInfo(finDoc),
            ],
          ),
        ],
      );

  static Widget buildCustomerAddress(User customer) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${customer.company!.name}"),
          Text("${customer.firstName ?? ''} ${customer.lastName ?? ''}",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(customer.email ?? ''),
        ],
      );

  static Widget buildFinDocInfo(FinDoc info) {
    final titles = <String>[
      '${info.docType} Number:',
      '${info.docType} Date:',
    ];
    final data = <String>[
      info.id()!,
      info.creationDate!.toString().substring(0, 10),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(titles.length, (index) {
        final title = titles[index];
        final value = data[index];

        return buildText(title: title, value: value, width: 200);
      }),
    );
  }

  static buildSupplierAddress(Company supplier) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          supplier.image != null
              ? pw.Container(
                  width: 200,
                  height: 100,
                  child: pw.Image(pw.MemoryImage(supplier.image!)))
              : Text(""),
          Text("${supplier.name}",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 1 * PdfPageFormat.mm),
          Text(supplier.email!),
        ],
      );

  static Widget buildTitle(FinDoc finDoc) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${finDoc.docType}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          Text(finDoc.description ?? 'Description here'),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );

  static Widget buildFinDoc(FinDoc finDoc) {
    final headers = ['Description', 'Type', 'Quantity', 'Unit Price', 'Total'];
    final data = finDoc.items.map((item) {
      return [
        item.description,
        item.itemType!.itemTypeName,
        item.quantity,
        item.price,
        item.price! * item.quantity!,
      ];
    }).toList();

    return Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerRight,
        3: Alignment.centerRight,
        4: Alignment.centerRight,
        5: Alignment.centerRight,
      },
    );
  }

  static Widget buildTotal(FinDoc finDoc) {
    final netTotal = finDoc.items
        .map((item) => item.price! * item.quantity!)
        .reduce((item1, item2) => item1 + item2);
    //final vatPercent = finDoc.items.first.vat;
    //final vat = netTotal * vatPercent;
    final total = netTotal; // + vat;

    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Spacer(flex: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildText(
                  title: 'Net total',
                  value: netTotal.toString(),
                  unite: true,
                ),
//                buildText(
//                  title: 'Vat ${vatPercent * 100} %',
//                  value: vat,
//                  unite: true,
//                ),
                Divider(),
                buildText(
                  title: 'Total amount due',
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  value: total.toString(),
                  unite: true,
                ),
                SizedBox(height: 2 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
                SizedBox(height: 0.5 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter(Company company, FinDoc finDoc) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
//          buildSimpleText(title: 'Address', value: finDoc.supplier.address),
          SizedBox(height: 1 * PdfPageFormat.mm),
//          buildSimpleText(title: 'Paypal', value: finDoc.supplier.paymentInfo),
        ],
      );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(value),
      ],
    );
  }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: unite ? style : null),
        ],
      ),
    );
  }
}
