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
import 'package:json_annotation/json_annotation.dart';
import 'models.dart';

part 'authenticate_model.g.dart';

@JsonSerializable()
class Authenticate {
  String? apiKey;
  String? moquiSessionToken;
  String? ownerPartyId;
  Company? company; //postall address not used here, use user comp address
  User? user; // user has a company companyAddress
  Stats? stats;

  Authenticate({
    this.apiKey,
    this.moquiSessionToken,
    this.ownerPartyId,
    this.company, //postall address not used here, use user comp address
    this.user, // user has a company companyAddress
    this.stats,
  });

  factory Authenticate.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateFromJson(json['authenticate']);
  Map<String, dynamic> toJson() => _$AuthenticateToJson(this);

  @override
  String toString() => '$ownerPartyId ${user.toString()} ${company.toString()}';
}
