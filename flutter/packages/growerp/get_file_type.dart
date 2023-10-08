import 'package:growerp_models_new/growerp_models_new.dart';

import 'file_type_model.dart';

FileType getFileType(String param) {
  if (param.isEmpty) {
    print("filename missing should be glAccount.csv or products.scv etc...");
    return FileType.unknown;
  }
  var fileName = param.split('.')[0];
  fileName = fileName.split('/').last;
  return FileType.values
      .firstWhere((e) => e.name == fileName, orElse: () => FileType.unknown);
}
