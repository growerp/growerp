import 'package:growerp_models/growerp_models.dart';

import '../common.dart';

/// Check the access of the curent logged in user
/// in order from write -> my (only write/read my records) -> read -> no access
bool access(UserGroup? userGroup, MenuOption menuOption) {
  //print("===1=check for $userGroup in write: ${menuOption.writeGroups}");
  if (menuOption.writeGroups != null &&
      menuOption.writeGroups!.contains(userGroup)) return true;
  //print("==2==check for $userGroup in my: ${menuOption.myGroups}");
  if (menuOption.myGroups != null && menuOption.myGroups!.contains(userGroup)) {
    return true;
  }
  //print("=3===check for $userGroup in read: ${menuOption.readGroups}");
  if (menuOption.readGroups != null &&
      menuOption.readGroups!.contains(userGroup)) return true;
  return false;
}
