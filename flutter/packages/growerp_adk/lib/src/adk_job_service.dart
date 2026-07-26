/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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

  Future<List<AdkJob>> list({String? search}) async {
    final result = await _client.getAdkJobs(search: search);
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
