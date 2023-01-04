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

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domains/domains.dart';

part 'authenticate_model.freezed.dart';
part 'authenticate_model.g.dart';

@freezed
class Authenticate with _$Authenticate {
  Authenticate._();
  factory Authenticate({
    final String? apiKey,
    String? moquiSessionToken,
    Company? company, //postall address not used here, use user comp address
    User? user, // user has a company companyAddress
    Stats? stats,
  }) = _Authenticate;

  factory Authenticate.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateFromJson(json);
}
