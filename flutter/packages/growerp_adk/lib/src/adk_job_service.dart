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

import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

class AdkJobService {
  final RestClient _client;

  AdkJobService._(this._client);

  static Future<AdkJobService> create() async {
    final client = RestClient(await buildDioClient());
    return AdkJobService._(client);
  }

  Future<List<AdkJob>> list() async {
    final result = await _client.getAdkJobs();
    return result.adkJobs;
  }

  Future<void> clearLock(String jobName) async {
    await _client.clearAdkJobLock(jobName: jobName);
  }

  Future<void> pause(String jobName) async {
    await _client.updateAdkJobPaused(jobName: jobName, paused: true);
  }

  Future<void> resume(String jobName) async {
    await _client.updateAdkJobPaused(jobName: jobName, paused: false);
  }
}
