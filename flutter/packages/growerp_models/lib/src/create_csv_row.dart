String createCsvRow(List<String> rows) {
  // convert to csv format
  String result = '';
  for (String row in rows) {
    if (result.isNotEmpty) {
      result += ',';
    }
    result += '\"${row.replaceAll('"', '""')}\"';
  }
  result += '\r\n';
  return result;
}
