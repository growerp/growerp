import 'package:dcli/dcli.dart';
import 'package:growerp_models_new/growerp_models_new.dart';

import 'file_type_model.dart';
import 'get_file_type.dart';

List<String> getFiles(String fileDirectory,
    {FileType overrrideFileType = FileType.unknown}) {
  List<String> files = [];

  if (isFile(fileDirectory) &&
          (getFileType(fileDirectory) != FileType.unknown) ||
      overrrideFileType != FileType.unknown) {
    return [fileDirectory];
  }

  if (isDirectory(fileDirectory)) {
    if (overrrideFileType != FileType.unknown) {
      print("override Filetype not used when specifying a directory");
    }
    var error = false;
    List<String> fileNames =
        find('*.csv', workingDirectory: fileDirectory).toList();
    for (String file in fileNames) {
      if (getFileType(file) == FileType.unknown) {
        print("File: $file is not the correct filename, "
            "valid names are ${FileType.values.join(',')}");
        error = true;
      }
      files.add(file);
    }
    if (error == true) {
      return [];
    }
  }
  return files;
}
