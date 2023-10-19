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
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import '../create_csv_row.dart';
import 'models.dart';
import '../json_converters.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  factory User({
    String? partyId, // allocated by system cannot be changed.
    String? pseudoId,
    String? userId, // allocated by system cannot be changed.
    String? firstName,
    String? lastName,

    /// login account is required if disabled just dummy
    bool? loginDisabled,
    String? loginName,

    /// email address of this person
    String? email,

    /// when customer register they can give their telephonenr to use as membername
    String? telephoneNr,

    /// admin, employee, customer, supplier etc...
    // ignore: invalid_annotation_target
    @JsonKey(name: 'userGroupId') @UserGroupConverter() UserGroup? userGroup,
    // the localization variables
    @Default('EN') String language,
    @Default('THB') String currency,
    @Default('GMT') String timeZone,
    @Uint8ListConverter() Uint8List? image,
    Company? company,
  }) = _User;
  User._();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @override
  String toString() => 'User $firstName $lastName [$partyId] sec: $userGroup '
      ' email: $email'
      'company: ${company!.name}[${company!.partyId}] size: ${image?.length}';
}

String userCsvFormat =
    'User Id, First Name*, Last Name*, Email, Login Name, Telephone Number '
    'User Group, language, image, Company Name, Company Role\r\n';
int userCsvLength = userCsvFormat.split(',').length;

List<User> CsvToUsers(String csvFile) {
  List<User> users = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    users.add(
      User(
        pseudoId: row[0],
        firstName: row[1],
        lastName: row[2],
        email: row[3].contains('@example.com') // avoid duplicated emails
            ? (Random().nextInt(1000).toString() + row[3])
            : row[3],
        loginName: row[4].contains('@@') ||
                row[4].contains('@example.com') // avoid duplicated usernames
            ? (Random().nextInt(1000).toString() + row[4])
            : row[4],
        telephoneNr: row[5],
        userGroup: UserGroup.getByValue(row[6]),
        language: row[7],
        image: row[8].isNotEmpty ? base64.decode(row[8]) : null,
        company: Company(name: row[9], role: Role.getByValue(row[10])),
      ),
    );
  }
  return users;
}

String CsvFromUsers(List<User> users) {
  var csv = [userCsvFormat];
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
      user.image != null ? base64.encode(user.image!) : '',
      user.company?.name ?? '',
      user.company!.role.toString(),
    ], userCsvLength));
  }
  return csv.join();
}
