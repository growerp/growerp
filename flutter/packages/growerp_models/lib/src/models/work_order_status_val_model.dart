/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
