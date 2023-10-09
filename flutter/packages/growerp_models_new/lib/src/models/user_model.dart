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
import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

import '../create_csv_row.dart';
import 'models.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  String? partyId; // allocated by system cannot be changed.
  String? pseudoId;
  String? userId; // allocated by system cannot be changed.
  String? firstName;
  String? lastName;

  /// login account is required if disabled just dummy
  bool? loginDisabled;
  String? loginName;

  /// email address of this person
  String? email;

  /// when customer register they can give their telephonenr to use as membername
  String? telephoneNr;

  /// admin, employee, customer, supplier etc...
  // ignore: invalid_annotation_target
  @JsonKey(name: 'userGroupId')
  @UserGroupConverter()
  UserGroup? userGroup;
  // the localization variables
  String language;
  String currency;
  String timeZone;
  @Uint8ListConverter()
  Uint8List? image;
  Company? company;

  User({
    this.partyId, // allocated by system cannot be changed.
    this.pseudoId,
    this.userId, // allocated by system cannot be changed.
    this.firstName,
    this.lastName,

    /// login account is required if disabled just dummy
    this.loginDisabled,
    this.loginName,

    /// email address of this person
    this.email,

    /// when customer register they can give their telephonenr to use as membername
    this.telephoneNr,

    /// admin, employee, customer, supplier etc...
    // ignore: invalid_annotation_target
    this.userGroup,
    // the localization variables
    this.language = 'EN',
    this.currency = 'THB',
    this.timeZone = 'GMT',
    this.image,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() => 'User $firstName $lastName [$partyId] sec: $userGroup '
      'company: ${company!.name}[${company!.partyId}] size: ${image?.length}';
}

String UserCsvFormat() =>
    'User Id, First Name*, Last Name*, Email, Login Name, Telephone Number '
    'User Group, language, image, Company Name\r\n';

List<String> UserCsvToJson(String csvFile) {
  List<String> users = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    users.add(jsonEncode(User(
      pseudoId: row[0],
      firstName: row[1],
      lastName: row[2],
      email: row[3],
      loginName: row[4],
      telephoneNr: row[5],
      userGroup: UserGroup.getByValue(row[6]),
      language: row[7],
      image: row[8].isNotEmpty ? Uint8List.fromList(row[8].codeUnits) : null,
      company: Company(name: row[9]),
    ).toJson()));
  }

  return users;
}

String CsvFromUsers(List<User> users) {
  var csv = [];
  for (User user in users) {
    csv.add(createCsvRow([
      user.pseudoId ?? '',
      user.firstName ?? '',
      user.lastName ?? '',
      user.email ?? '',
      user.loginName ?? '',
      user.telephoneNr ?? '',
      user.userGroup.toString(),
      user.language,
      user.image != null ? user.image!.toList().toString() : '',
      user.company?.name ?? '',
    ]));
  }
  return csv.join();
}