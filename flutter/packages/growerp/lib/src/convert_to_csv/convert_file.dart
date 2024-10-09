// specify file wide changes here
import 'file_type_model.dart';

String convertFile(FileType fileType, String string, String fileName) {
  /// file type dependent changes here,
  switch (fileType) {
    case FileType.glAccount:
      string = string
          .replaceFirst(
              '10205,"Checking Acct, Mission Bank",Cash,,\n',
              '10205,"Checking Acct, Mission Bank",Cash,,\n'
                  '10206,Deleted bank account,Cash,,\n')
          .replaceFirst(
              "27500,Loan - Kern Schools C. U.,Long Term Liabilities,,\n",
              "27500,Loan - Kern Schools C. U.,Long Term Liabilities,,\n"
                  "27600,Loan - Old,Long Term Liabilities,,\n")
          .replaceFirst(
              "10100,Cash on Hand,", "10000,Assets,Cash,,\n10100,Cash on Hand,")
          .replaceFirst(
              "10100,Cash on Hand,", "10000,Assets,Cash,,\n10100,Cash on Hand,")
          .replaceFirst(
              "39005,Capital,", "30000,Equity,Equity-Retained Earnings,,\n39005,Capital,")
          .replaceFirst("85000,Discount for Early Payment,",
              "80000,Discounts,Cash,,\n85000,Discount for Early Payment,")
          .replaceFirst('48000,Sales Returns and Allowances,Income,',
              '48000,Sales Returns and Allowances,Customer Returns (contra),')
          .replaceFirst('49000,Sales Discounts,Income,',
              '49000,Sales Discounts,Discounts and Write-downs (contra),')
          .replaceFirst('50050,Raw Materials,Cost of Sales,',
              '50050,Raw Materials,Good and Material Cost (contra),')
          .replaceFirst('89500,Discount for Early Payment,Cost of Sales,',
              '89500,Discount for Early Payment,Expenses (contra),');
    default:
      string = string.replaceAll('�', '°');
      string = string.replaceAll(',"H1002",', ',"1002",');
  }

  /// filename dependent changes here
  switch (fileName) {
    default:
  }
  return string;
}
