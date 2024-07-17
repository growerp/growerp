String createCsvRow(List<String> rows, int length) {
  // convert to csv format
  String result = '';
  for (String row in rows) {
    if (row.isEmpty) {
      result += ',';
    } else {
      result += '"${row.replaceAll('"', '""')}",';
    }
  }
  for (int index = rows.length; index < length; index++) {
    result += ',';
  }

  result += '\r\n';
  return result;
}
