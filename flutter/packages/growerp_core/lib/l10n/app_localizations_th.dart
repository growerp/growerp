// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get loginWithExistingUserName => 'เข้าสู่ระบบด้วยชื่อผู้ใช้ที่มีอยู่';

  @override
  String get createPassword => 'สร้างรหัสผ่านใหม่';

  @override
  String username(String username) {
    return 'ชื่อผู้ใช้: $username';
  }

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get passwordHelper =>
      'อย่างน้อย 8 ตัวอักษร ประกอบด้วยตัวอักษร ตัวเลข และอักขระพิเศษ ไม่ใช้รหัสผ่านเดิม';

  @override
  String get passwordError => 'กรุณาป้อนรหัสผ่านแรก';

  @override
  String get passwordValidationError =>
      'อย่างน้อย 8 ตัวอักษร ประกอบด้วยตัวอักษร ตัวเลข และอักขระพิเศษ';

  @override
  String get verifyPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get verifyPasswordHelper => 'ป้อนรหัสผ่านใหม่อีกครั้ง';

  @override
  String get verifyPasswordError => 'ป้อนรหัสผ่านอีกครั้งเพื่อยืนยัน';

  @override
  String get passwordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get submitNewPassword => 'ส่งรหัสผ่านใหม่';

  @override
  String get completeRegistration => 'ทำการลงทะเบียนให้เสร็จสมบูรณ์';

  @override
  String get welcome => 'ยินดีต้อนรับ!';

  @override
  String get enterCompanyAndCurrency =>
      'กรุณาป้อนทั้งชื่อบริษัทและสกุลเงินสำหรับบริษัทใหม่';

  @override
  String get enterCompanyName => 'กรุณาป้อนชื่อบริษัทที่คุณทำงาน (ไม่บังคับ)';

  @override
  String get businessCompanyName => 'ชื่อบริษัทธุรกิจ';

  @override
  String get businessNameError =>
      'กรุณาป้อนชื่อธุรกิจ (ป้อน \"Private\" สำหรับบุคคลธรรมดา)';

  @override
  String get currency => 'สกุลเงิน';

  @override
  String get currencyError => 'ต้องระบุสกุลเงิน!';

  @override
  String get generateDemoData => 'สร้างข้อมูลตัวอย่าง';

  @override
  String get demoData => 'ข้อมูลตัวอย่าง';

  @override
  String get continueButton => 'ดำเนินการต่อ';

  @override
  String get usernameEmail => 'ชื่อผู้ใช้/อีเมล';

  @override
  String get usernameEmailError => 'กรุณาป้อนชื่อผู้ใช้หรืออีเมล';

  @override
  String get passwordError2 => 'กรุณาป้อนรหัสผ่านของคุณ';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get forgotPassword => 'ลืม/เปลี่ยนรหัสผ่าน?';

  @override
  String get subscription => 'การสมัครสมาชิก';

  @override
  String currentPaymentMethod(String ccDescription) {
    return 'วิธีการชำระเงินปัจจุบันของคุณ:\n$ccDescription';
  }

  @override
  String get trialPeriod =>
      'คุณมีระยะเวลาทดลองใช้ 2 สัปดาห์\nเราจะเรียกเก็บเงินก็ต่อเมื่อคุณไม่ยกเลิก\nก่อนเวลานั้น';

  @override
  String get testSystem =>
      'นี่คือระบบทดสอบ\nดังนั้นบัตรเครดิตนี้จะได้รับการอนุมัติเสมอ';

  @override
  String get paymentPlan => 'แผนการชำระเงิน';

  @override
  String get selectPlanError => 'กรุณาเลือกแผนเดียวเท่านั้น';

  @override
  String get creditCardInfo => 'ข้อมูลบัตรเครดิต';

  @override
  String get creditCardDetails => 'ป้อนรายละเอียดบัตรเครดิตของคุณ';

  @override
  String get number => 'หมายเลข';

  @override
  String get numberHint => 'XXXX XXXX XXXX XXXX';

  @override
  String get expiryDate => 'เดือน/ปีที่หมดอายุ';

  @override
  String get expiryDateHint => 'XX/XX';

  @override
  String get cvvCode => 'รหัส CVV';

  @override
  String get cvvHint => 'XXX';

  @override
  String get nameOnCard => 'ชื่อบนบัตร';

  @override
  String get payWithinWeek => 'ชำระเงินภายในหนึ่งสัปดาห์';

  @override
  String get registerAndCharge => 'ลงทะเบียนและเรียกเก็บเงินใน 2 สัปดาห์';

  @override
  String get sendNewPassword => 'ส่งรหัสผ่านใหม่ทางอีเมล';

  @override
  String get email => 'อีเมล:';

  @override
  String get ok => 'ตกลง';

  @override
  String get deleteWarning =>
      'โปรดทราบว่าคุณจะถูกบล็อกไม่ให้ใช้ระบบ\nการกระทำนี้ไม่สามารถยกเลิกได้!';

  @override
  String get onlyUserDelete => 'ลบเฉพาะผู้ใช้';

  @override
  String get userAndCompanyDelete => 'ลบผู้ใช้และบริษัท';

  @override
  String get deleteYourself => 'ลบตัวคุณเอง';

  @override
  String get deleteYourselfAndCompany => 'ลบตัวคุณเองและบริษัท (ถ้ามี)?';

  @override
  String get registration => 'การลงทะเบียน';

  @override
  String get firstName => 'ชื่อจริง';

  @override
  String get firstNameError => 'กรุณาป้อนชื่อจริงของคุณ';

  @override
  String get lastName => 'นามสกุล';

  @override
  String get lastNameError => 'กรุณาป้อนนามสกุลของคุณ';

  @override
  String get tempPassword => 'รหัสผ่านชั่วคราวจะถูกส่งทางอีเมล';

  @override
  String get emailAddress => 'ที่อยู่อีเมล';

  @override
  String get emailAddressError => 'กรุณาป้อนที่อยู่อีเมล';

  @override
  String get emailAddressError2 => 'นี่ไม่ใช่อีเมลที่ถูกต้อง';

  @override
  String get register => 'ลงทะเบียน';

  @override
  String get aboutGrowERP => 'เกี่ยวกับ GrowERP';

  @override
  String aboutApp(String appName) {
    return 'เกี่ยวกับ GrowERP และแอป $appName นี้';
  }

  @override
  String version(String version, String build) {
    return 'เวอร์ชัน $version บิวด์ #$build';
  }

  @override
  String copyright(int year) {
    return '© GrowERP, $year';
  }

  @override
  String get viewReadme => 'ดู Readme';

  @override
  String get viewLicense => 'ดูใบอนุญาต';

  @override
  String get contributing => 'การมีส่วนร่วม';

  @override
  String get privacyCodeOfConduct => 'ความเป็นส่วนตัว, จรรยาบรรณ';

  @override
  String get openSourceLicenses => 'ใบอนุญาตโอเพนซอร์ส';

  @override
  String get enterBackendUrl => 'ป้อน URL แบ็กเอนด์และแชทในรูปแบบ: xxx.yyy.zzz';

  @override
  String get backendServer => 'เซิร์ฟเวอร์แบ็กเอนด์:';

  @override
  String get fieldRequired => 'ต้องระบุข้อมูลในฟิลด์นี้!';

  @override
  String get chatServer => 'เซิร์ฟเวอร์แชท:';

  @override
  String get companyPartyId => 'partyId ของบริษัทหลัก:';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get restart => 'เริ่มต้นใหม่';

  @override
  String get main => 'หลัก';

  @override
  String get noAccess => 'ไม่สามารถเข้าถึงตัวเลือกใดๆ';

  @override
  String get addNew => 'เพิ่มใหม่';

  @override
  String get chat => 'แชท';

  @override
  String get goHome => 'ไปที่หน้าหลัก';

  @override
  String get test => 'ทดสอบ';

  @override
  String get theme => 'ธีม';

  @override
  String get error => 'ข้อผิดพลาด: ไม่ควรมาถึงที่นี่';

  @override
  String get noAccessHere => 'ไม่สามารถเข้าถึงตัวเลือกใดๆ ที่นี่, ';

  @override
  String get noRestRequests => 'ไม่พบคำขอ REST';

  @override
  String get cannotLoadRestRequests => 'ไม่สามารถโหลดคำขอ REST ได้!';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get restRequestDetails => 'รายละเอียดคำขอ REST';

  @override
  String get dateTime => 'วันที่/เวลา';

  @override
  String get unknown => 'ไม่ทราบ';

  @override
  String get user => 'ผู้ใช้';

  @override
  String get notAvailable => 'ไม่มีข้อมูล';

  @override
  String get loginName => 'ชื่อล็อกอิน';

  @override
  String get requestName => 'ชื่อคำขอ';

  @override
  String get serverIp => 'IP เซิร์ฟเวอร์';

  @override
  String get serverHost => 'โฮสต์เซิร์ฟเวอร์';

  @override
  String get runningTime => 'เวลาทำงาน';

  @override
  String get ms => ' มิลลิวินาที';

  @override
  String get status => 'สถานะ';

  @override
  String get success => 'สำเร็จ';

  @override
  String get slowHit => 'การเข้าถึงช้า';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่';

  @override
  String get errorMessage => 'ข้อความแสดงข้อผิดพลาด:';

  @override
  String get requestUrl => 'URL คำขอ:';

  @override
  String get referrerUrl => 'URL ผู้อ้างอิง:';

  @override
  String get parameters => 'พารามิเตอร์:';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get welcomeToGrowERPBusinessSystem =>
      'ยินดีต้อนรับสู่ระบบธุรกิจ GrowERP';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get registerNewCompanyAndAdmin => 'ลงทะเบียนบริษัทและผู้ดูแลระบบใหม่';

  @override
  String get create => 'สร้าง';

  @override
  String get update => 'อัปเดต';

  @override
  String get customer => 'ลูกค้า';

  @override
  String get supplier => 'ซัพพลายเออร์';

  @override
  String get andAtLeastOne => 'และอย่างน้อยหนึ่ง ';

  @override
  String get itemIsRequired => 'รายการจำเป็นต้องระบุ';
}
