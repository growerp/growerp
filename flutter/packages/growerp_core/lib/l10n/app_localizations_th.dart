// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String aboutApp(String appName) {
    return 'เกี่ยวกับ $appName';
  }

  @override
  String get aboutGrowERP => 'เกี่ยวกับ GrowERP';

  @override
  String get accounts => 'บัญชี';

  @override
  String get addNew => 'เพิ่มใหม่';

  @override
  String get andAtLeastOne => 'และอย่างน้อยหนึ่ง ';

  @override
  String get backendServer => 'เซิร์ฟเวอร์แบ็กเอนด์';

  @override
  String get balanceSheet => 'งบดุล';

  @override
  String get balanceSummary => 'สรุปยอดคงเหลือ';

  @override
  String get businessCompanyName => 'ต้องระบุชื่อบริษัท!';

  @override
  String get businessNameError => 'ชื่อบริษัทจำเป็นต้องระบุ!';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get cannotLoadRestRequests => 'ไม่สามารถโหลดคำขอ REST ได้!';

  @override
  String get chat => 'แชท';

  @override
  String get chatServer => 'เซิร์ฟเวอร์แชท';

  @override
  String get completeRegistration => 'ลงทะเบียนให้เสร็จสิ้น';

  @override
  String get companyPartyId => 'รหัสบริษัท';

  @override
  String get continueButton => 'ดำเนินการต่อ';

  @override
  String get contributing => 'การมีส่วนร่วม';

  @override
  String copyright(String year) {
    return '© $year GrowERP.com';
  }

  @override
  String get create => 'สร้าง';

  @override
  String get createPassword => 'สร้างรหัสผ่าน';

  @override
  String get creditCardDetails => 'รายละเอียดบัตรเครดิต';

  @override
  String get creditCardInfo => 'ข้อมูลบัตรเครดิต';

  @override
  String get currency => 'สกุลเงิน';

  @override
  String get currencyError => 'สกุลเงินจำเป็นต้องระบุ!';

  @override
  String currentPaymentMethod(String method) {
    return 'วิธีการชำระเงินปัจจุบัน: $method';
  }

  @override
  String get customer => 'ลูกค้า';

  @override
  String get cvvCode => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get dateTime => 'วันที่/เวลา';

  @override
  String get deleteWarning => 'คำเตือนการลบ';

  @override
  String get deleteYourself => 'ลบตัวคุณเอง';

  @override
  String get deleteYourselfAndCompany => 'ลบตัวคุณเองและบริษัท';

  @override
  String get demoData => 'ข้อมูลตัวอย่าง';

  @override
  String get email => 'อีเมล';

  @override
  String get emailAddress => 'ที่อยู่อีเมล';

  @override
  String get emailAddressError => 'ที่อยู่อีเมลจำเป็นต้องระบุ!';

  @override
  String get emailAddressError2 => 'รูปแบบที่อยู่อีเมลไม่ถูกต้อง!';

  @override
  String get enterBackendUrl => 'ป้อน URL แบ็กเอนด์';

  @override
  String get enterCompanyAndCurrency => 'กรุณาป้อนชื่อบริษัทและสกุลเงิน';

  @override
  String get enterCompanyName => 'ป้อนชื่อบริษัท';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get errorMessage => 'ข้อความข้อผิดพลาด';

  @override
  String get expiryDate => 'MM/YY';

  @override
  String get expiryDateHint => '12/25';

  @override
  String get fieldRequired => 'ช่องนี้จำเป็นต้องระบุ!';

  @override
  String get firstName => 'ชื่อ';

  @override
  String get firstNameError => 'ชื่อจำเป็นต้องระบุ!';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get generateDemoData => 'สร้างข้อมูลตัวอย่าง?';

  @override
  String get goHome => 'กลับหน้าหลัก';

  @override
  String get invoice => 'ใบแจ้งหนี้';

  @override
  String get itemIsRequired => 'รายการเป็นสิ่งจำเป็น';

  @override
  String get itemTypes => 'ประเภทรายการ';

  @override
  String get journal => 'สมุดรายวัน';

  @override
  String get lastName => 'นามสกุล';

  @override
  String get lastNameError => 'นามสกุลจำเป็นต้องระบุ!';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get loginName => 'ชื่อผู้ใช้';

  @override
  String get loginWithExistingUserName => 'เข้าสู่ระบบด้วยชื่อผู้ใช้ที่มีอยู่';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get main => 'หลัก';

  @override
  String get mainDashboard => 'แดชบอร์ดหลัก';

  @override
  String get ms => 'มส.';

  @override
  String get nameOnCard => 'ชื่อบนบัตร';

  @override
  String get no => 'ไม่';

  @override
  String get noAccess => 'ไม่มีสิทธิ์เข้าถึงหน้านี้!';

  @override
  String get noAccessHere => 'ไม่มีสิทธิ์เข้าถึงที่นี่!';

  @override
  String get noRestRequests => 'ไม่พบคำขอ REST...';

  @override
  String get notAvailable => 'ไม่มี';

  @override
  String get number => 'หมายเลข';

  @override
  String get numberHint => '1234 5678 9012 3456';

  @override
  String get ok => 'ตกลง';

  @override
  String get onlyUserDelete => 'ลบเฉพาะผู้ใช้ ไม่ลบบริษัท';

  @override
  String get openInvoices => 'ใบแจ้งหนี้ที่ค้างชำระ:';

  @override
  String get openSourceLicenses => 'ลิขสิทธิ์โอเพ่นซอร์ส';

  @override
  String get order => 'คำสั่งซื้อ';

  @override
  String get parameters => 'พารามิเตอร์';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get passwordError => 'รหัสผ่านจำเป็นต้องระบุ!';

  @override
  String get passwordError2 => 'รหัสผ่านจำเป็นต้องระบุ!';

  @override
  String get passwordHelper => 'อย่างน้อย 5 ตัวอักษร';

  @override
  String get passwordMismatch => 'รหัสผ่านไม่ตรงกัน!';

  @override
  String get passwordValidationError => 'รหัสผ่านต้องมีอย่างน้อย 5 ตัวอักษร';

  @override
  String get payment => 'การชำระเงิน';

  @override
  String get paymentPlan => 'แผนการชำระเงิน';

  @override
  String get paymentTypes => 'ประเภทการชำระเงิน';

  @override
  String get payWithinWeek => 'ชำระภายในสัปดาห์';

  @override
  String get privacyCodeOfConduct => 'ความเป็นส่วนตัว/จรรยาบรรณ';

  @override
  String get referrerUrl => 'URL อ้างอิง';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get register => 'ลงทะเบียน';

  @override
  String get registerAndCharge => 'ลงทะเบียนและเรียกเก็บเงิน';

  @override
  String get registerNewCompanyAndAdmin => 'ลงทะเบียนบริษัทและผู้ดูแลใหม่';

  @override
  String get registration => 'การลงทะเบียน';

  @override
  String get requestName => 'ชื่อคำขอ';

  @override
  String get requestUrl => 'URL คำขอ';

  @override
  String get restart => 'เริ่มใหม่';

  @override
  String get restRequestDetails => 'รายละเอียดคำขอ REST';

  @override
  String get revenueExpense => 'รายได้/ค่าใช้จ่าย';

  @override
  String get runningTime => 'เวลาที่ใช้';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get selectPlanError => 'กรุณาเลือกแผน!';

  @override
  String get sendNewPassword => 'ส่งรหัสผ่านใหม่';

  @override
  String get serverHost => 'โฮสต์เซิร์ฟเวอร์';

  @override
  String get serverIp => 'IP เซิร์ฟเวอร์';

  @override
  String get shipment => 'การจัดส่ง';

  @override
  String get slowHit => 'ตอบสนองช้า';

  @override
  String get status => 'สถานะ';

  @override
  String get submitNewPassword => 'ส่งรหัสผ่านใหม่';

  @override
  String get subscription => 'การสมัครสมาชิก';

  @override
  String get success => 'สำเร็จ';

  @override
  String get supplier => 'ผู้จำหน่าย';

  @override
  String get tempPassword => 'รหัสผ่านชั่วคราวจะถูกส่งทางอีเมล';

  @override
  String get test => 'ทดสอบ';

  @override
  String get testSystem => 'ระบบทดสอบ';

  @override
  String get theme => 'ธีม';

  @override
  String get timePeriods => 'ช่วงเวลา';

  @override
  String get transaction => 'ธุรกรรม';

  @override
  String get transactions => 'ธุรกรรม';

  @override
  String get trialPeriod => 'ช่วงทดลองใช้';

  @override
  String get unknown => 'ไม่ทราบ';

  @override
  String get update => 'อัปเดต';

  @override
  String get user => 'ผู้ใช้';

  @override
  String get userAndCompanyDelete => 'ลบผู้ใช้และบริษัท';

  @override
  String username(String username) {
    return 'ชื่อผู้ใช้: $username';
  }

  @override
  String get usernameEmail => 'ชื่อผู้ใช้/อีเมล';

  @override
  String get usernameEmailError => 'ชื่อผู้ใช้/อีเมลจำเป็นต้องระบุ!';

  @override
  String get verifyPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get verifyPasswordError => 'ยืนยันรหัสผ่านจำเป็นต้องระบุ!';

  @override
  String get verifyPasswordHelper => 'ป้อนรหัสผ่านอีกครั้ง';

  @override
  String version(String version, String build) {
    return 'เวอร์ชั่น: $version บิลด์: $build';
  }

  @override
  String get viewLicense => 'ดูลิขสิทธิ์';

  @override
  String get viewReadme => 'ดู Readme';

  @override
  String get welcome => 'ยินดีต้อนรับ!';

  @override
  String get welcomeToGrowERPBusinessSystem =>
      'ยินดีต้อนรับสู่ระบบธุรกิจ GrowERP!';

  @override
  String get yes => 'ใช่';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get accounting => 'บัญชี';

  @override
  String get accountingDashboard => 'แดชบอร์ดบัญชี';

  @override
  String get accountingLedger => 'บัญชีแยกประเภท';

  @override
  String get accountingPurch => 'บัญชีซื้อ';

  @override
  String get accountingSales => 'บัญชีขาย';

  @override
  String get administrators => 'ผู้ดูแลระบบ';

  @override
  String get allOpportunities => 'โอกาสทั้งหมด';

  @override
  String get assets => 'สินทรัพย์';

  @override
  String get catalog => 'แคตตาล็อก';

  @override
  String get categories => 'หมวดหมู่';

  @override
  String get company => 'บริษัท';

  @override
  String get crm => 'CRM';

  @override
  String get customers => 'ลูกค้า';

  @override
  String get employees => 'พนักงาน';

  @override
  String get incomingInvoices => 'ใบแจ้งหนี้ที่เข้ามา';

  @override
  String get incomingPayments => 'การชำระเงินที่เข้ามา';

  @override
  String get incomingShipments => 'การจัดส่งที่เข้ามา';

  @override
  String get inventory => 'สินค้าคงคลัง';

  @override
  String get leads => 'ลูกค้าเป้าหมาย';

  @override
  String get ledgerAccnt => 'บัญชีแยกประเภท';

  @override
  String get ledgerJournals => 'สมุดรายวันบัญชี';

  @override
  String get ledgerTransaction => 'ธุรกรรมบัญชี';

  @override
  String get ledgerTree => 'โครงสร้างบัญชี';

  @override
  String get myTodoTasks => 'งานที่ต้องทำของฉัน';

  @override
  String get opportunities => 'โอกาส';

  @override
  String get orders => 'คำสั่งซื้อ';

  @override
  String get organization => 'องค์กร';

  @override
  String get otherEmployees => 'พนักงานคนอื่น';

  @override
  String get outgoingInvoices => 'ใบแจ้งหนี้ที่ออก';

  @override
  String get outgoingPayments => 'การชำระเงินที่ออก';

  @override
  String get outgoingShipments => 'การจัดส่งที่ออก';

  @override
  String get paymtTypes => 'ประเภทการชำระเงิน';

  @override
  String get planSelection => 'การเลือกแผน';

  @override
  String get products => 'สินค้า';

  @override
  String get purchaseOrders => 'ใบสั่งซื้อ';

  @override
  String get purchaseUnpaidInvoices => 'ใบแจ้งหนี้ซื้อที่ยังไม่ชำระ';

  @override
  String get reports => 'รายงาน';

  @override
  String get requests => 'คำขอ';

  @override
  String get salesOpenInvoices => 'ใบแจ้งหนี้ขายที่เปิดอยู่';

  @override
  String get salesOrders => 'ใบสั่งขาย';

  @override
  String get setUp => 'ตั้งค่า';

  @override
  String get subscriptions => 'การสมัครสมาชิก';

  @override
  String get suppliers => 'ผู้จำหน่าย';

  @override
  String get website => 'เว็บไซต์';

  @override
  String get whLocations => 'ตำแหน่งคลังสินค้า';

  @override
  String get checkIn => 'เช็คอิน';

  @override
  String get checkOut => 'เช็คเอาท์';

  @override
  String get inOut => 'เข้า/ออก';

  @override
  String get myHotel => 'โรงแรมของฉัน';

  @override
  String get reservations => 'การจอง';

  @override
  String get rooms => 'ห้องพัก';

  @override
  String get roomTypes => 'ประเภทห้องพัก';

  @override
  String get tasks => 'งาน';

  @override
  String get myOpportunities => 'โอกาสของฉัน';

  @override
  String get clients => 'ลูกค้า';

  @override
  String get staff => 'พนักงาน';

  @override
  String get applications => 'แอปพลิเคชัน';

  @override
  String get restRequests => 'คำขอ REST';
}
