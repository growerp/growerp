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

enum FinDocStatusVal {
  inPreparation('FinDocPrep', 'In Preparation', 'In Preparation'),
  created('FinDocCreated', 'Created', 'Created'),
  approved('FinDocApproved', 'Checked In', 'Approved'),
  completed('FinDocCompleted', 'Checked Out', 'Completed'),
  cancelled('FinDocCancelled', 'Cancelled', 'Cancelled'),
  unknown('Unknown', 'Unknown', 'Unknown');

  const FinDocStatusVal(this.value, this.hotel, this.other);

  final String value; // value used in backend
  final String hotel; // used in hotel app
  final String other; // value used in other apps

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
        return [inPreparation, approved, cancelled];
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
