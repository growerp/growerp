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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'models.dart';
import '../create_csv_row.dart';

part 'website_model.freezed.dart';
part 'website_model.g.dart';

@freezed
class Website with _$Website {
  Website._();
  factory Website({
    @Default('') String id,
    @Default('') String hostName,
    @Default('') String title,
    @Default([]) List<Content> websiteContent,
    @Default([]) List<Category> websiteCategories,
    @Default([]) List<Category> productCategories,
    @Default('') String colorJson,
    @Default('') String obsidianName,
    @Default('') String measurementId,
  }) = _Website;

  factory Website.fromJson(Map<String, dynamic> json) =>
      _$WebsiteFromJson(json["website"]);
}

String websiteCsvFormat =
    'Host name, title, Category name, Product Name,  Color , measurement,'
    'category name1, category name2, category name3, category name4, category name5, '
    'product name1, product name2, product name3, product name4, product name5, '
    'content path1, title1, text1, image1, seqId1,'
    'content path2, title2, text2, image2, seqId2,'
    'content path3, title3, text3, image3, seqId3,'
    'content path4, title4, text4, image4, seqId4,'
    'content path5, title5, text5, image5, seqId5,'
    ' \r\n';
int websiteCsvLength = glAccountCsvFormat.split(',').length;

// import
Website csvToWebsite(String csvFile) {
  Website website = Website();
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    website = Website(
      hostName: row[0],
      title: row[1],
      colorJson: row[2],
      obsidianName: row[3],
      measurementId: row[4],
      websiteCategories: [
        Category(categoryName: row[5]),
        Category(categoryName: row[6]),
        Category(categoryName: row[7]),
        Category(categoryName: row[8]),
        Category(categoryName: row[9]),
      ],
      productCategories: [
        Category(categoryName: row[10]),
        Category(categoryName: row[11]),
        Category(categoryName: row[12]),
        Category(categoryName: row[13]),
        Category(categoryName: row[14]),
      ],
      websiteContent: [
        Content(
            path: row[15],
            title: row[16],
            text: row[17],
            image: row[18].isNotEmpty ? base64.decode(row[18]) : null,
            seqId: int.parse(row[19])),
        Content(
            path: row[20],
            title: row[21],
            text: row[22],
            image: row[23].isNotEmpty ? base64.decode(row[23]) : null,
            seqId: int.parse(row[24])),
        Content(
            path: row[25],
            title: row[26],
            text: row[27],
            image: row[28].isNotEmpty ? base64.decode(row[28]) : null,
            seqId: int.parse(row[29])),
        Content(
            path: row[30],
            title: row[31],
            text: row[32],
            image: row[33].isNotEmpty ? base64.decode(row[33]) : null,
            seqId: int.parse(row[34])),
        Content(
            path: row[35],
            title: row[36],
            text: row[37],
            image: row[38].isNotEmpty ? base64.decode(row[38]) : null,
            seqId: int.parse(row[39])),
      ],
    );
  }
  return website;
}

// export
String csvFromWebsite(Website website) {
  var csv = [websiteCsvFormat];
  csv.add(createCsvRow([
    website.hostName,
    website.title,
    website.colorJson,
    website.measurementId,
    website.websiteCategories.isNotEmpty
        ? website.websiteCategories[0].categoryName
        : '',
    website.websiteCategories.length > 1
        ? website.websiteCategories[1].categoryName
        : '',
    website.websiteCategories.length > 2
        ? website.websiteCategories[2].categoryName
        : '',
    website.websiteCategories.length > 3
        ? website.websiteCategories[3].categoryName
        : '',
    website.websiteCategories.length > 4
        ? website.websiteCategories[4].categoryName
        : '',
    website.productCategories.isNotEmpty
        ? website.productCategories[0].categoryName
        : '',
    website.productCategories.isNotEmpty
        ? website.productCategories[1].categoryName
        : '',
    website.productCategories.isNotEmpty
        ? website.productCategories[2].categoryName
        : '',
    website.productCategories.isNotEmpty
        ? website.productCategories[3].categoryName
        : '',
    website.productCategories.isNotEmpty
        ? website.productCategories[4].categoryName
        : '',
    website.websiteContent.isNotEmpty ? website.websiteContent[0].path : '',
    website.websiteContent.isNotEmpty ? website.websiteContent[0].title : '',
    website.websiteContent.isNotEmpty ? website.websiteContent[0].text : '',
    website.websiteContent.isNotEmpty && website.websiteContent[0].image != null
        ? base64.encode(website.websiteContent[0].image!)
        : '',
    website.websiteContent.isNotEmpty
        ? website.websiteContent[0].seqId.toString()
        : '',
    website.websiteContent.length > 1 ? website.websiteContent[1].path : '',
    website.websiteContent.length > 1 ? website.websiteContent[1].title : '',
    website.websiteContent.length > 1 ? website.websiteContent[1].text : '',
    website.websiteContent.length > 1 && website.websiteContent[1].image != null
        ? base64.encode(website.websiteContent[1].image!)
        : '',
    website.websiteContent.length > 1
        ? website.websiteContent[1].seqId.toString()
        : '',
    website.websiteContent.length > 2 ? website.websiteContent[2].path : '',
    website.websiteContent.length > 2 ? website.websiteContent[2].title : '',
    website.websiteContent.length > 2 ? website.websiteContent[2].text : '',
    website.websiteContent.length > 2 && website.websiteContent[2].image != null
        ? base64.encode(website.websiteContent[2].image!)
        : '',
    website.websiteContent.length > 2
        ? website.websiteContent[2].seqId.toString()
        : '',
    website.websiteContent.length > 3 ? website.websiteContent[3].path : '',
    website.websiteContent.length > 3 ? website.websiteContent[3].title : '',
    website.websiteContent.length > 3 ? website.websiteContent[3].text : '',
    website.websiteContent.length > 3 && website.websiteContent[3].image != null
        ? base64.encode(website.websiteContent[3].image!)
        : '',
    website.websiteContent.length > 3
        ? website.websiteContent[3].seqId.toString()
        : '',
    website.websiteContent.length > 4 ? website.websiteContent[4].path : '',
    website.websiteContent.length > 4 ? website.websiteContent[4].title : '',
    website.websiteContent.length > 4 ? website.websiteContent[4].text : '',
    website.websiteContent.length > 4 && website.websiteContent[4].image != null
        ? base64.encode(website.websiteContent[0].image!)
        : '',
    website.websiteContent.length > 4
        ? website.websiteContent[4].seqId.toString()
        : '',
  ], websiteCsvLength));
  return csv.join();
}
