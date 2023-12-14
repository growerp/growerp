import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:logger/logger.dart';

import 'file_type_model.dart';
import 'get_file_type.dart';

List<String> getFiles(String fileName, Logger logger,
    {FileType overrrideFileType = FileType.unknown}) {
  List<String> files = [];
  // filename?
  if (isFile(fileName)) {
    return [fileName];
  }
  // directory?
  if (isDirectory(fileName)) {
    var error = false;
    // if filetype, just that file out of that directory
    if (overrrideFileType != FileType.unknown)
      return find('${overrrideFileType.name}.csv', workingDirectory: fileName)
          .toList();
    List<String> fileNames = find('*.csv', workingDirectory: fileName).toList();
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
    return files;
  }
  logger.e("Specified fileName: $fileName not a file AND not a directory!");
  exit(1);
}
