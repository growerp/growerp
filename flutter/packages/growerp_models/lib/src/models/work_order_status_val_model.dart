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

enum WorkOrderStatusVal {
  inPlanning('WeInPlanning', 'In Planning'),
  approved('WeApproved', 'Approved'),
  inProgress('WeInProgress', 'In Progress'),
  complete('WeComplete', 'Complete'),
  unknown('Unknown', 'Unknown');

  const WorkOrderStatusVal(this.value, this.name);

  final String value; // value used in backend
  final String name; // value used in frontend

  static final Map<String, WorkOrderStatusVal> byValue = {};
  static WorkOrderStatusVal? getByValue(String value) {
    if (byValue.isEmpty) {
      for (WorkOrderStatusVal statusVal in WorkOrderStatusVal.values) {
        byValue[statusVal.value] = statusVal;
      }
    }
    return byValue[value];
  }

  @override
  String toString() {
    return value;
  }
}
