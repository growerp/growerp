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

// a replacement for enum:
// https://medium.com/@ra9r/overcoming-the-limitations-of-dart-enum-8866df8a1c47

/// acting role within the system.
class UserGroup {
  final String _name;
  final String _id;
  final bool _companyEmployee;
  const UserGroup._(this._name, this._id, this._companyEmployee);

  @override
  String toString() {
    return _name;
  }

  String id() {
    return _id;
  }

  bool isEmployee() {
    return _companyEmployee;
  }

  static List<UserGroup> userGroupList() {
    return [Employee, Admin, Customer, Lead, Supplier];
  }

  static List<UserGroup> companyUserGroupList() {
    return [Employee, Admin, Customer, Lead, Supplier];
  }

  static List<String> getIdList(List<UserGroup> userGroupList) {
    List<String> idList = [];
    for (UserGroup item in userGroupList) idList.add(item._id);
    return idList;
  }

  /// special employee all access within the owner company
  static const UserGroup Admin =
      UserGroup._('Administrator', 'GROWERP_M_ADMIN', true);

  /// employee limited access within the owner company:
  /// 1. no accounting
  /// 2. no editing of company level data
  static const UserGroup Employee = UserGroup._(
      'Employee', 'GROWERP_M_EMPLOYEE', true); // employee of owner company
  static const UserGroup Customer =
      UserGroup._('Customer', 'GROWERP_M_CUSTOMER', false);
  static const UserGroup Lead = UserGroup._('Lead', 'GROWERP_M_LEAD', false);
  static const UserGroup Supplier =
      UserGroup._('Supplier', 'GROWERP_M_SUPPLIER', false);
  static const UserGroup SuperAdmin =
      UserGroup._('Super Administrator', 'ADMIN', false);
  static const UserGroup Undefined =
      UserGroup._('Undefined', '', false); // not defined

  static UserGroup? tryParse(String val) {
    switch (val) {
      case 'GROWERP_M_ADMIN':
        return Admin;
      case 'GROWERP_M_EMPLOYEE':
        return Employee;
      case 'GROWERP_M_CUSTOMER':
        return Customer;
      case 'GROWERP_M_LEAD':
        return Lead;
      case 'GROWERP_M_SUPPLIER':
        return Supplier;
      default:
        return Undefined;
    }
  }
}
