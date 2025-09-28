# GrowERP - แพลตฟอร์ม ERP แบบโมดูลาร์โอเพนซอร์ส

[![License: CC0-1.0](https://img.shields.io/badge/License-CC0%201.0-lightgrey.svg)](http://creativecommons.org/publicdomain/zero/1.0/)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.1-blue.svg)](https://flutter.dev/)
[![Moqui](https://img.shields.io/badge/Moqui-Framework-green.svg)](https://www.moqui.org/)

GrowERP เป็นแอปพลิเคชัน ERP โอเพนซอร์สหลายแพลตฟอร์มที่สร้างขึ้นด้วยสถาปัตยกรรมแบบโมดูลาร์ที่ช่วยให้สามารถขยายและปรับแต่งได้อย่างที่ไม่เคยมีมาก่อน ไม่ว่าคุณจะเป็นธุรกิจขนาดเล็กหรือองค์กรขนาดใหญ่ GrowERP สามารถปรับให้เข้ากับความต้องการของคุณผ่านระบบบล็อกการสร้างที่ยืดหยุ่น

## 🚀 เริ่มต้นอย่างรวดเร็ว

### ลองใช้ GrowERP ตอนนี้

**แอปพลิเคชันเวอร์ชันใช้งานจริง:** ต้องใช้บัตรเครดิตพร้อมทดลองใช้ 2 สัปดาห์
- **แอปผู้ดูแลระบบพร้อมฟังก์ชันครบถ้วน**: [เว็บ](https://admin.growerp.com) | [Linux](https://snapcraft.io/growerp-admin) | [Windows](https://apps.microsoft.com/detail/9nwx6kftjnql?hl=en-US&gl=TH) | [MacOs](https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755) | [Android](https://play.google.com/store/apps/details?id=org.growerp.admin) | [iOS](https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755)

**แอปพลิเคชันที่มีให้ใช้งานจำกัดและอยู่ระหว่างการทดสอบ:** บัตรเครดิตจำลองจะได้รับการอนุมัติเสมอ
- **แอปผู้ดูแลระบบเวอร์ชันถัดไป**: [admin.growerp.org](https://admin.growerp.org)
- **โรงแรม**: [hotel.growerp.org](https://hotel.growerp.org)
- **ฟรีแลนซ์**: [freelance.growerp.org](https://freelance.growerp.org)

*สร้างบริษัทใหม่ เลือกข้อมูลตัวอย่าง และสำรวจได้เลย! ข้อมูลการเข้าสู่ระบบจะถูกส่งไปยังอีเมลของคุณ*

### ติดตั้งบนเครื่อง (วิธีง่าย)

```bash
dart pub global activate growerp
growerp install
```

<a href="https://studio.firebase.google.com/import?url=https%3A%2F%2Fgithub.com%2Fgrowerp%2Fgrowerp">
  <img height="32" alt="Open in Firebase Studio" src="https://cdn.firebasestudio.dev/btn/open_blue_32.svg">
</a>

## 📚 เอกสารประกอบ

> **🚀 เริ่มต้นอย่างรวดเร็ว**: หากคุณเพิ่งเริ่มใช้ GrowERP ให้เริ่มต้นด้วย [ภาพรวมการขยายระบบ](./docs/README.md) เพื่อดูแผนงานที่สมบูรณ์ จากนั้นตรวจสอบ [คู่มือการพัฒนา Building Blocks](./docs/Building_Blocks_Development_Guide.md) สำหรับการพัฒนาส่วนหน้า หรือ [คู่มือส่วนประกอบแบ็กเอนด์](./docs/Backend_Components_Development_Guide.md) สำหรับการพัฒนาแบ็กเอนด์

### 🏗️ การพัฒนาหลักและสถาปัตยกรรม

- **[📖 ภาพรวมการขยายระบบ](./docs/README.md)** - คู่มือฉบับสมบูรณ์เกี่ยวกับสถาปัตยกรรมแบบโมดูลาร์และรูปแบบการพัฒนาของ GrowERP
- **[🧩 คู่มือ Building Blocks](./docs/Building_Blocks_Development_Guide.md)** - สร้างแพ็คเกจ Flutter (แพ็คเกจ growerp_*)
- **[⚙️ คู่มือส่วนประกอบแบ็กเอนด์](./docs/Backend_Components_Development_Guide.md)** - พัฒนาส่วนประกอบและบริการของ Moqui
- **[🎨 รูปแบบการออกแบบ](./docs/GrowERP_Design_Patterns.md)** - รูปแบบและข้อตกลงที่กำหนดไว้เพื่อการพัฒนาที่สอดคล้องกัน
- **[📝 เทมเพลตโค้ด](./docs/GrowERP_Code_Templates.md)** - เทมเพลตพร้อมใช้งานเพื่อการพัฒนาที่รวดเร็ว
- **[🤖 คู่มือการพัฒนา AI](./docs/GrowERP_AI_Instructions.md)** - แนวทางปฏิบัติที่ดีที่สุดสำหรับการพัฒนาโดยใช้ AI ช่วย

### 🔧 การรวมระบบและ API

- **[🔗 คู่มือโมเดลข้อมูล](./docs/basic_explanation_of_the_frontend_REST_Backend_data_models.md)** - การรวมโมเดลข้อมูลส่วนหน้าและแบ็กเอนด์
- **[🤖 การรวม AI (เซิร์ฟเวอร์ MCP)](./moqui/runtime/component/mcp/docs/README.md)** - เซิร์ฟเวอร์ Model Context Protocol สำหรับระบบธุรกิจอัตโนมัติด้วย AI
- **[💳 การประมวลผลการชำระเงินผ่าน Stripe](./docs/Stripe_Payment_Processing_Documentation.md)** - คู่มือการรวมระบบการชำระเงินฉบับสมบูรณ์
- **[🌐 การแจ้งเตือนผ่าน WebSocket](./docs/WebSocket_Notification_System.md)** - ระบบการแจ้งเตือนแบบเรียลไทม์
- **[🕐 การจัดการเขตเวลา](./docs/GrowERP_Timezone_Management_Guide.md)** - จัดการความแตกต่างของเขตเวลาระหว่างไคลเอนต์และเซิร์ฟเวอร์

### 🚀 การปรับใช้และการดำเนินงาน

- **[🐳 การติดตั้ง Docker](./docker/README.md)** - การปรับใช้และการพัฒนาแบบคอนเทนเนอร์
- **[📦 การแจกจ่ายแบบ Snap](./docs/snap_linux_distribution.md)** - การแจกจ่ายแพ็คเกจ Snap สำหรับ Linux
- **[⚙️ การเลือกระบบ URL แบ็กเอนด์](./docs/Backend_URL_Selection_System_Documentation.md)** - การกำหนดค่าและการกำหนดเส้นทางแบ็กเอนด์

### 📋 ธุรกิจและการจัดการ

- **[📊 สรุปสำหรับผู้บริหาร](./docs/Management_Summary_Open_Source_Extensibility.md)** - ภาพรวมเชิงกลยุทธ์สำหรับผู้มีอำนาจตัดสินใจ
- **[📈 การจัดการลูกค้าเป้าหมาย](./docs/leads_upload_process.md)** - กระบวนการนำเข้าและส่งออกลูกค้าเป้าหมาย
- **[💰 ฟังก์ชันการสมัครสมาชิก](./docs/Moqui_Subscription_Function.md)** - การจัดการการสมัครสมาชิกและการเรียกเก็บเงิน

### 🤝 การมีส่วนร่วมและชุมชน

- **[🔧 คู่มือการมีส่วนร่วม](./CONTRIBUTING.md)** - วิธีการมีส่วนร่วมใน GrowERP
- **[📜 หลักปฏิบัติ](./CODE_OF_CONDUCT.md)** - แนวทางและข้อคาดหวังของชุมชน
- **[📄 ใบอนุญาต](./LICENSE)** - CC0 1.0 Universal (สาธารณสมบัติ)
- **[🎯 พรอมต์สำหรับการพัฒนา](./docs/prompts.md)** - พรอมต์ AI สำหรับช่วยในการพัฒนา

### 📖 แหล่งข้อมูลเพิ่มเติม

- **[🌐 เอกสารสำหรับผู้ใช้](https://www.growerp.com)** - คู่มือสำหรับผู้ใช้ปลายทาง บทช่วยสอน และการสนับสนุน
- **[📚 เอกสารทางเทคนิค](./GrowERPObs/)** - เอกสารทางเทคนิคและตัวอย่างที่ครอบคลุม
- **[📂 ตัวอย่างเอกสาร](./docs/examples/)** - ตัวอย่างโค้ดและตัวอย่างการนำไปใช้งาน

### 📝 สถานะและการบำรุงรักษาเอกสาร

เอกสารของ GrowERP ได้รับการบำรุงรักษาและอัปเดตอย่างสม่ำเสมอ คุณสมบัติหลัก:

- **📊 ครอบคลุมครบถ้วน**: คู่มือโดยละเอียดกว่า 25 ฉบับ ครอบคลุมทุกด้านของการพัฒนาและการปรับใช้
- **🔗 การอ้างอิงโยง**: เอกสารทั้งหมดมีลิงก์ไปยังหัวข้อและตัวอย่างที่เกี่ยวข้อง
- **🎯 เน้นกรณีการใช้งาน**: เอกสารจัดระเบียบตามความต้องการและประสบการณ์ของนักพัฒนา
- **📱 หลายแพลตฟอร์ม**: ครอบคลุมการพัฒนาสำหรับเว็บ, Android, iOS, Linux, Windows และ macOS
- **🤖 พร้อมสำหรับ AI**: รวมถึงคู่มือการรวม AI และเอกสารเซิร์ฟเวอร์ MCP

> **💡 เคล็ดลับการนำทางเอกสาร**:
> เริ่มต้นด้วย [ภาพรวมการขยายระบบ](./docs/README.md) เพื่อดูแผนงานที่สมบูรณ์ของเอกสารทั้งหมดที่มีอยู่ คู่มือแต่ละฉบับมีการอ้างอิงโยงและตัวอย่างเชิงปฏิบัติเพื่อช่วยให้คุณค้นพบสิ่งที่ต้องการสำหรับกรณีการใช้งานเฉพาะของคุณ

> **🔄 การมีส่วนร่วมในเอกสาร**:
> พบสิ่งที่ขาดหายไปหรือล้าสมัย? เรายินดีรับการมีส่วนร่วมในเอกสาร! ดู [คู่มือการมีส่วนร่วม](./CONTRIBUTING.md) ของเราสำหรับวิธีปรับปรุงเอกสาร

## 🏛️ ภาพรวมสถาปัตยกรรม

GrowERP ใช้สถาปัตยกรรมแบบโมดูลาร์ที่ส่งเสริมการนำกลับมาใช้ใหม่และการขยายระบบ:

```
┌─────────────────────────────────────────────────────────────┐
│                    ชั้นแอปพลิเคชัน (Applications Layer)      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ แอปผู้ดูแลระบบ │ │ แอปโรงแรม  │ │แอปฟรีแลนซ์ │ │กำหนดเอง...│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  ชั้น Building Blocks                        │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────┐ │
│ │growerp_core  │ │growerp_catalog│ │growerp_order │ │ ...  │ │
│ │growerp_models│ │growerp_inventory│ │_accounting  │ │      │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ └──────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    ชั้นแบ็กเอนด์ (Backend Layer)             │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────┐ │
│ │ส่วนประกอบ GrowERP│ │ส่วนประกอบที่กำหนดเอง│ │Mantle UDM    │ │Moqui │ │
│ │              │ │              │ │Mantle USL    │ │Frame │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ └──────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 🧩 Building Blocks (ส่วนหน้า)
- **growerp_core** - เทมเพลตพื้นฐานและส่วนประกอบ UI
- **growerp_models** - โมเดลข้อมูลและไคลเอนต์ API
- **growerp_catalog** - การจัดการสินค้าและหมวดหมู่
- **growerp_inventory** - การจัดการคลังสินค้าและสต็อก
- **growerp_order_accounting** - คำสั่งซื้อ ใบแจ้งหนี้ และการบัญชี
- **growerp_user_company** - การจัดการผู้ใช้และบริษัท
- **growerp_marketing** - แคมเปญการตลาดและการวิเคราะห์
- **growerp_website** - การจัดการเนื้อหาเว็บไซต์
- **growerp_activity** - การติดตามงานและกิจกรรม
- **growerp_chat** - การสื่อสารแบบเรียลไทม์

### ⚙️ ส่วนประกอบแบ็กเอนด์
- **Moqui Framework** - เฟรมเวิร์กแบ็กเอนด์ระดับองค์กร
- **REST APIs** - การแปลงข้อมูลเป็น JSON และการรับรองความถูกต้องอัตโนมัติ
- **Entity Engine** - ORM พร้อมการดำเนินการ CRUD อัตโนมัติ
- **Service Engine** - ตรรกะทางธุรกิจพร้อมธุรกรรม
- **Security** - การควบคุมการเข้าถึงตามบทบาท

## 🌟 คุณสมบัติหลัก

### ✨ สำหรับธุรกิจ
- **หลายแพลตฟอร์ม** - เว็บ, Android, iOS จากโค้ดเบสเดียว
- **การออกแบบแบบโมดูลาร์** - ใช้เฉพาะสิ่งที่คุณต้องการ
- **เฉพาะทางอุตสาหกรรม** - แอปพลิเคชันที่สร้างไว้ล่วงหน้าสำหรับภาคส่วนต่างๆ
- **ขยายขนาดได้** - จากธุรกิจขนาดเล็กไปจนถึงองค์กรขนาดใหญ่
- **โอเพนซอร์ส** - ไม่มีค่าธรรมเนียมใบอนุญาต ควบคุมได้เต็มที่

### 🛠️ สำหรับนักพัฒนา
- **สถาปัตยกรรมที่ขยายได้** - สร้าง Building Blocks และส่วนประกอบที่กำหนดเอง
- **เทคโนโลยีที่ทันสมัย** - ส่วนหน้า Flutter, แบ็กเอนด์ Moqui
- **เอกสารที่ครอบคลุม** - คู่มือโดยละเอียดสำหรับทุกด้าน
- **ชุมชนที่กระตือรือร้น** - สภาพแวดล้อมการพัฒนาแบบร่วมมือ
- **แนวทางปฏิบัติที่ดีที่สุด** - รูปแบบและข้อตกลงที่กำหนดไว้

### 🏢 สำหรับองค์กร
- **คุ้มค่า** - ลดต้นทุนการเป็นเจ้าของทั้งหมด (TCO) 60%
- **การพัฒนาที่รวดเร็ว** - พัฒนาแอปพลิเคชันเร็วขึ้น 50%
- **ปรับแต่งได้** - ปรับให้เข้ากับความต้องการทางธุรกิจเฉพาะ
- **รองรับอนาคต** - สถาปัตยกรรมแบบโมดูลาร์รองรับการพัฒนา
- **ขับเคลื่อนโดยชุมชน** - ได้รับประโยชน์จากนวัตกรรมร่วมกัน

## 🚀 เริ่มต้นใช้งาน

### ข้อกำหนดเบื้องต้น

- **Java JDK 11** - [ดาวน์โหลด](https://www.oracle.com/th/java/technologies/javase/jdk11-archive-downloads.html)
- **Java JDK 17** - [ดาวน์โหลด](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) (สำหรับ Gradle 8+)
- **Flutter stable** - [ติดตั้ง](https://flutter.dev/)
- **Chrome Browser** - [ดาวน์โหลด](https://www.google.com/chrome/)
- **Git** - [ดาวน์โหลด](https://git-scm.com/downloads)
- **Android Studio** - [ดาวน์โหลด](https://developer.android.com/studio) (ไม่บังคับ)
- **VS Code** - [ดาวน์โหลด](https://code.visualstudio.com/) (ไม่บังคับ)

### การติดตั้งด้วยตนเอง

1. **โคลนที่เก็บ:**
   ```bash
   git clone https://github.com/growerp/growerp
   cd growerp
   ```

2. **เริ่มแบ็กเอนด์** (ในเทอร์มินัลแยกต่างหาก):
   ```bash
   cd moqui
   # ครั้งแรกเท่านั้น
   ./gradlew build
   java -jar moqui.war load types=seed,seed-initial,install no-run-es
   
   # การเริ่มต้นปกติ
   java -jar moqui.war no-run-es
   ```

3. **รันแอปพลิเคชัน Flutter:**
   ```bash
   cd flutter/packages/admin
   # ครั้งแรกเท่านั้น
   dart pub global activate melos 3.4.0
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   melos clean
   melos bootstrap
   melos l10n --no-select
   melos build --no-select
   
   # การเริ่มต้นปกติ
   flutter run
   ```

4. **เข้าถึงส่วนผู้ดูแลระบบแบ็กเอนด์:**
   - URL: http://localhost:8080/vapps
   - ผู้ใช้: SystemSupport
   - รหัสผ่าน: moqui

### การติดตั้ง Docker

สำหรับการติดตั้งโดยใช้ Docker โปรดดู [Docker README](./docker/README.md)

## 🎯 กรณีการใช้งานและแอปพลิเคชัน

### 🏢 แอปพลิเคชันผู้ดูแลระบบ
โซลูชัน ERP ที่สมบูรณ์พร้อม:
- การจัดการแคตตาล็อกสินค้า
- การติดตามสินค้าคงคลัง
- การประมวลผลคำสั่งซื้อ
- การบัญชีและการออกใบแจ้งหนี้
- การจัดการผู้ใช้และบริษัท
- การจัดการเนื้อหาเว็บไซต์
- แคมเปญการตลาด

### 🏨 แอปพลิเคชันโรงแรม
เชี่ยวชาญสำหรับธุรกิจบริการ:
- การจัดการห้องพัก
- ระบบการจอง
- บริการสำหรับแขก
- การทำความสะอาด
- การเรียกเก็บเงินและการบัญชี

### 💼 แอปพลิเคชันฟรีแลนซ์
เน้นการจัดการโครงการ:
- การจัดการลูกค้า
- การติดตามเวลา
- การจัดระเบียบโครงการ
- การออกใบแจ้งหนี้
- การติดตามกิจกรรม

### 🔧 แอปพลิเคชันที่กำหนดเอง
สร้างแอปพลิเคชันของคุณเองโดยใช้:
- Building Blocks ที่มีอยู่
- ส่วนประกอบที่กำหนดเอง
- เวิร์กโฟลว์เฉพาะอุตสาหกรรม
- ส่วนต่อประสานผู้ใช้ที่ปรับแต่งได้

## 🤝 การมีส่วนร่วม

เรายินดีรับการมีส่วนร่วมจากนักพัฒนาทุกระดับความสามารถ! นี่คือวิธีที่คุณสามารถช่วยได้:

### 🎯 พื้นที่การมีส่วนร่วม
- **🐛 การแก้ไขข้อบกพร่อง** - รายงานและแก้ไขปัญหา
- **✨ คุณสมบัติใหม่** - Building Blocks, ส่วนประกอบแบ็กเอนด์, การรวมระบบ
- **📚 เอกสาร** - ปรับปรุงคู่มือ, เพิ่มตัวอย่าง, การแปล
- **🧪 การทดสอบ** - การทดสอบหน่วย, การทดสอบการรวม, การประกันคุณภาพ
- **🎨 UI/UX** - การปรับปรุงการออกแบบ, การเข้าถึง, ธีม

### 🚀 เริ่มต้น
1. อ่าน [คู่มือการมีส่วนร่วม](./CONTRIBUTING.md) ของเรา
2. ตรวจสอบ [เอกสารการขยายระบบ](./docs/README.md)
3. ปฏิบัติตาม [หลักปฏิบัติ](./CODE_OF_CONDUCT.md) ของเรา
4. เข้าร่วมการสนทนาในชุมชน

### 📈 พื้นที่ที่มีลำดับความสำคัญสูง
- Building Blocks เฉพาะอุตสาหกรรม (การดูแลสุขภาพ, การศึกษา, การผลิต)
- โมดูลการรวม (การชำระเงิน, การจัดส่ง, การวิเคราะห์)
- การแปลและการปรับให้เข้ากับสากล
- การปรับปรุงประสิทธิภาพและความสามารถในการขยายขนาด

## 📱 ภาพหน้าจอ

### แอปพลิเคชันผู้ดูแลระบบ

<div align="center">

#### ภาพหน้าจอบนมือถือ
| เมนูหลัก | สินค้า | เว็บไซต์ |
|-----------|----------|---------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_main_menu.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_catalog_products.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_website.png" width="200"> |

| การบัญชี | บัญชีแยกประเภท | บริษัท |
|------------|--------|---------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_accounting.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_ledger.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_company.png" width="200"> |

#### ภาพหน้าจอบนเว็บ/แท็บเล็ต
| เมนูหลัก |
|-----------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_main_menu.png" width="600"> |

| การจัดการบริษัท |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_company.png" width="600"> |

| การจัดการเว็บไซต์ |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_website.png" width="600"> |

| การจัดการคำสั่งซื้อ |
|------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_orders.png" width="600"> |

| การบัญชี |
|------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_accounting.png" width="600"> |

| บัญชีแยกประเภท |
|--------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_ledger.png" width="600"> |

| แคตตาล็อกสินค้า |
|-----------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_products.png" width="600"> |

</div>

### แอปพลิเคชันโรงแรม

<div align="center">

#### ภาพหน้าจอบนมือถือ
| มุมมองรายวัน | เมนูรายสัปดาห์ | ห้องพัก |
|------------|-------------|-------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/main-day.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/main-week-menu.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/rooms.png" width="200"> |

| การจอง | การบัญชี | บัญชีแยกประเภท |
|--------------|------------|--------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/reservations.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/accounting.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/ledger.png" width="200"> |

#### ภาพหน้าจอบนเว็บ/แท็บเล็ต
| มุมมองรายวัน |
|------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/main-day.png" width="600"> |

| มุมมองรายสัปดาห์ |
|-------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/main-week.png" width="600"> |

| การจัดการห้องพัก |
|-----------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/rooms.png" width="600"> |

| ระบบการจอง |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/reservations.png" width="600"> |

| การบัญชี |
|------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/accounting.png" width="600"> |

| บัญชีแยกประเภททางการเงิน |
|------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/ledger.png" width="600"> |

</div>

### เว็บไซต์ธุรกิจที่สร้างขึ้น

<div align="center">

| เว็บไซต์อีคอมเมิร์ซ |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/GrowERPObs/media/website.png" width="600"> |

</div>

## 🌐 ชุมชนและการสนับสนุน

### 📞 ติดต่อและสนับสนุน
- **อีเมล**: support@growerp.com
- **เว็บไซต์**: [www.growerp.com](https://www.growerp.com)
- **GitHub Issues**: [รายงานข้อบกพร่องและขอคุณสมบัติ](https://github.com/growerp/growerp/issues)
- **GitHub Discussions**: [การสนทนาในชุมชน](https://github.com/growerp/growerp/discussions)

### 🤝 ชุมชน
- **ผู้มีส่วนร่วม**: เข้าร่วมชุมชนนักพัฒนาที่กำลังเติบโตของเรา
- **เอกสาร**: ช่วยปรับปรุงและแปลเอกสาร
- **การทดสอบ**: ทดสอบคุณสมบัติใหม่และรายงานปัญหา
- **การให้คำปรึกษา**: เรียนรู้จากผู้มีส่วนร่วมที่มีประสบการณ์

### 📈 สถานะโครงการ
- **ใบอนุญาต**: CC0 1.0 Universal (สาธารณสมบัติ)
- **สถานะ**: กำลังพัฒนาอย่างต่อเนื่อง
- **ความเสถียร**: พร้อมใช้งานจริง
- **ชุมชน**: ระบบนิเวศโอเพนซอร์สที่กำลังเติบโต

## 🎯 แผนงาน

### 🔮 คุณสมบัติที่จะมาถึง
- การตอบสนองบนมือถือที่ปรับปรุงแล้ว
- การรายงานและการวิเคราะห์ขั้นสูง
- โมดูลเฉพาะอุตสาหกรรมเพิ่มเติม
- การปรับปรุงการปรับให้เข้ากับสากล
- การเพิ่มประสิทธิภาพ

### 🚀 วิสัยทัศน์ระยะยาว
- ระบบนิเวศที่ครอบคลุมของ Building Blocks
- แพลตฟอร์มการขยายชั้นนำของอุตสาหกรรม
- ชุมชนผู้มีส่วนร่วมทั่วโลก
- ความสามารถในการขยายขนาดและประสิทธิภาพระดับองค์กร

---

<div align="center">

**🌟 ติดดาวที่เก็บนี้หากคุณพบว่า GrowERP มีประโยชน์!**

**🤝 เข้าร่วมชุมชนของเราและช่วยกำหนดอนาคตของ ERP โอเพนซอร์ส!**

[⭐ ติดดาว](https://github.com/growerp/growerp/stargazers) • [🍴 Fork](https://github.com/growerp/growerp/fork) • [📝 มีส่วนร่วม](./CONTRIBUTING.md) • [💬 สนทนา](https://github.com/growerp/growerp/discussions)

</div>