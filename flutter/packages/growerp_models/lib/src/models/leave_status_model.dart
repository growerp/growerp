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

/// Status of a leave request, backend field name: statusId.
enum LeaveStatus {
  pending('HrlsPending', 'Pending'),
  approved('HrlsApproved', 'Approved'),
  rejected('HrlsRejected', 'Rejected'),
  cancelled('HrlsCancelled', 'Cancelled'),
  unknown('Unknown', 'Unknown');

  const LeaveStatus(this.value, this.name);

  final String value; // value used in backend
  final String name; // value used in frontend

  static final Map<String, LeaveStatus> byValue = {};
  static LeaveStatus? getByValue(String value) {
    if (byValue.isEmpty) {
      for (LeaveStatus status in LeaveStatus.values) {
        byValue[status.value] = status;
      }
    }
    return byValue[value];
  }

  @override
  String toString() {
    return value;
  }
}
