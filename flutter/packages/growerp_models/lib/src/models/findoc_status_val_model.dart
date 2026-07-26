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

enum FinDocStatusVal {
  inPreparation('FinDocPrep', 'Preparation', 'Preparation'),
  created('FinDocCreated', 'Created', 'Created'),
  approved('FinDocApproved', 'Checked In', 'Approved'),
  completed('FinDocCompleted', 'Checked Out', 'Completed'),
  cancelled('FinDocCancelled', 'Cancelled', 'Cancelled'),
  unknown('Unknown', 'Unknown', 'Unknown');

  const FinDocStatusVal(this.value, this.hotel, this.name);

  final String value; // value used in backend
  final String hotel; // used in hotel app
  final String name; // value used in other apps

  static final Map<String, FinDocStatusVal> byValue = {};
  static FinDocStatusVal? getByValue(String value) {
    if (byValue.isEmpty) {
      for (FinDocStatusVal finDocStatusVal in FinDocStatusVal.values) {
        byValue[finDocStatusVal.value] = finDocStatusVal;
      }
    }
    return byValue[value];
  }

  @override
  String toString() {
    return value;
  }

  static FinDocStatusVal? nextStatus(FinDocStatusVal currentStatus) {
    switch (currentStatus) {
      case inPreparation:
      case created:
        return approved;
      case approved:
        return completed;
      default:
        return currentStatus;
    }
  }

  // flag to show next Status icon: if fixed, then cannot change
  static bool statusFixed(FinDocStatusVal currentStatus) {
    switch (currentStatus) {
      case inPreparation:
        return false;
      case created:
        return false;
      case approved:
        return false;
      case completed:
        return true;
      case cancelled:
        return true;
      default:
        return true;
    }
  }

  static List<FinDocStatusVal> validStatusList(FinDocStatusVal? currentStatus) {
    currentStatus ??= created;
    switch (currentStatus) {
      case inPreparation:
        return [inPreparation, created, approved, cancelled];
      case created:
        return [created, approved, cancelled];
      case approved:
        return [approved, completed, cancelled];
      case completed:
        return [completed];
      case cancelled:
        return [cancelled];
      default:
        return [];
    }
  }
}
