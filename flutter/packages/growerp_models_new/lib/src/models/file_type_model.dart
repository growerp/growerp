enum FileType { glAccount, product, category, company, user, unknown }

FileType getFileType(String filePath) {
  String fileType = filePath.split('/').last;
  fileType = fileType.split('.').first;
  return FileType.values.firstWhere(
    (element) => element.name == fileType.split('.').first,
    orElse: () => FileType.unknown,
  );
}
