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
  InPreparation('FinDocPrep'),
  Created('FinDocCreated'),
  Approved('FinDocApproved'),
  Completed('FinDocCompleted'),
  Cancelled('FinDocCancelled'),
  Unknown('unknown');

  final String _name;
  const FinDocStatusVal(this._name);

  @override
  String toString() {
    return _name;
  }

  static FinDocStatusVal? tryParse(String val) {
    switch (val) {
      case 'FinDocPrep':
        return InPreparation;
      case 'FinDocCreated':
        return Created;
      case 'FinDocApproved':
        return Approved;
      case 'FinDocCompleted':
        return Completed;
      case 'FinDocCancelled':
        return Cancelled;
      default:
        return Unknown;
    }
  }

  static FinDocStatusVal? nextStatus(FinDocStatusVal currentStatus) {
    switch (currentStatus) {
      case InPreparation:
        return Created;
      case Created:
        return Approved;
      case Approved:
        return Completed;
      default:
        return currentStatus;
    }
  }

  static bool? statusFixed(FinDocStatusVal currentStatus) {
    switch (currentStatus) {
      case InPreparation:
        return false;
      case Created:
        return false;
      case Approved:
        return true;
      case Completed:
        return true;
      case Cancelled:
        return true;
      default:
        return true;
    }
  }
}
