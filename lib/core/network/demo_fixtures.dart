/// Static seed data for [DemoBackend] (`demo_backend.dart`) — the JSON
/// shapes here mirror the real backend's response bodies exactly (field
/// names/casing included) so the existing `fromJson` factories on
/// `CareService`, `CareMember`, `PaymentMethod`, etc. parse them unchanged.
library;

import '../config/app_config.dart';

const demoUserId = 'demo-00000000-0000-0000-0000-000000000001';
const demoSelfRelativeId = 'demo-relative-self';
const demoRelativeId = 'demo-relative-mother';

Map<String, dynamic> demoAuthMe() => {
  'id': demoUserId,
  'phone': AppConfig.demoPhone,
  'name': 'ผู้ใช้ทดสอบ Apple Review',
  'avatarUrl': '',
  'isActive': true,
  'information': {
    'firstName': 'ผู้ใช้ทดสอบ',
    'lastName': 'Apple Review',
    'nickname': 'ทดสอบ',
    'gender': 'male',
    'dateOfBirth': '1990-01-01',
    'email': 'demo@caremate.app',
  },
};

Map<String, dynamic> demoHealthInformation() => {
  'user_id': demoUserId,
  'emergency_contact_name': 'สมหญิง ใจดี',
  'emergency_contact_phone': '0812345678',
  'emergency_contact_relationship': 'มารดา',
  'blood_type': 'O',
  'allergies': 'ไม่มี',
  'congenital_diseases': 'ไม่มี',
  'current_medications': 'ไม่มี',
  'care_note': 'ไม่มีข้อควรระวังพิเศษ',
  'has_health_information': true,
};

Map<String, dynamic> demoAddress() => {
  'user_id': demoUserId,
  'address_line': '123 ถนนสุขุมวิท แขวงคลองตัน เขตคลองเตย',
  'subdistrict': 'คลองตัน',
  'district': 'คลองเตย',
  'province': 'กรุงเทพมหานคร',
  'postal_code': '10110',
  'latitude': 13.7563,
  'longitude': 100.5018,
  'has_address': true,
};

const demoServices = [
  {
    'id': 'demo-service-transport',
    'slug': 'transport',
    'name_th': 'เดินทางไปโรงพยาบาล',
    'name_en': 'Hospital Transport',
    'icon_name': 'transport',
    'base_fee': 300.0,
    'pricing_model': 'DISTANCE_TIERED',
    'rate_per_km': 15.0,
    'base_fee_first_km': 100.0,
    'is_active': true,
  },
  {
    'id': 'demo-service-home-care',
    'slug': 'home_care',
    'name_th': 'ดูแลผู้สูงอายุที่บ้าน',
    'name_en': 'Home Care',
    'icon_name': 'home_care',
    'base_fee': 250.0,
    'pricing_model': 'HOURLY',
    'rate_per_km': 0.0,
    'base_fee_first_km': 0.0,
    'is_active': true,
  },
  {
    'id': 'demo-service-medication',
    'slug': 'medication',
    'name_th': 'ดูแลการใช้ยา',
    'name_en': 'Medication Care',
    'icon_name': 'medication',
    'base_fee': 200.0,
    'pricing_model': 'HOURLY',
    'rate_per_km': 0.0,
    'base_fee_first_km': 0.0,
    'is_active': true,
  },
  {
    'id': 'demo-service-errand',
    'slug': 'errand',
    'name_th': 'ทำธุระให้',
    'name_en': 'Errand Service',
    'icon_name': 'errand',
    'base_fee': 150.0,
    'pricing_model': 'HOURLY',
    'rate_per_km': 0.0,
    'base_fee_first_km': 0.0,
    'is_active': true,
  },
];

const demoPaymentMethods = [
  {
    'id': 'demo-payment-method-promptpay',
    'slug': 'qr_promptpay',
    'name_th': 'พร้อมเพย์',
    'name_en': 'PromptPay',
    'icon_name': 'qr_promptpay',
    'is_active': true,
  },
];

List<Map<String, dynamic>> demoRelatives() => [
  {
    'id': demoSelfRelativeId,
    'firstName': 'ผู้ใช้ทดสอบ',
    'lastName': 'Apple Review',
    'nickname': 'ทดสอบ',
    'relationship': 'ตัวเอง',
    'registerAs': 'self',
    'phone': AppConfig.demoPhone,
    'gender': 'male',
    'dateOfBirth': '1990-01-01',
    'bloodType': 'O',
    'isDefault': true,
    'isActive': true,
    'addressLine': '123 ถนนสุขุมวิท แขวงคลองตัน เขตคลองเตย กรุงเทพมหานคร',
    'latitude': 13.7563,
    'longitude': 100.5018,
    'allergies': '',
    'congenitalDiseases': '',
    'careNote': '',
    'emergencyContactName': '',
    'emergencyContactPhone': '',
    'emergencyContactRelationship': '',
  },
  {
    'id': demoRelativeId,
    'firstName': 'สมหญิง',
    'lastName': 'ใจดี',
    'nickname': 'แม่',
    'relationship': 'มารดา',
    'registerAs': 'relative',
    'phone': '0812345678',
    'gender': 'female',
    'dateOfBirth': '1955-05-20',
    'bloodType': 'O',
    'isDefault': false,
    'isActive': true,
    'addressLine': '123 ถนนสุขุมวิท แขวงคลองตัน เขตคลองเตย กรุงเทพมหานคร',
    'latitude': 13.7563,
    'longitude': 100.5018,
    'allergies': 'ไม่มี',
    'congenitalDiseases': 'ความดันโลหิตสูง',
    'careNote': 'ต้องการผู้ช่วยพยุงเดิน',
    'emergencyContactName': 'ผู้ใช้ทดสอบ Apple Review',
    'emergencyContactPhone': AppConfig.demoPhone,
    'emergencyContactRelationship': 'บุตร',
  },
];

List<Map<String, dynamic>> demoBanners() => [
  {
    'id': 'demo-banner-1',
    'title': 'ยินดีต้อนรับสู่ CareMate',
    'body': 'บริการดูแลผู้สูงอายุและเดินทางไปโรงพยาบาล ครบจบในแอปเดียว',
    'image_url': null,
    'link_url': null,
    'is_active': true,
    'sort_order': 0,
  },
];

List<Map<String, dynamic>> demoNotifications() => [
  {
    'id': 'demo-notification-1',
    'title': 'ยินดีต้อนรับ',
    'body': 'ขอบคุณที่ทดลองใช้ CareMate',
    'type': 'system',
    'created_at': DateTime.now()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
    'read_at': null,
  },
];

/// 1x1 transparent PNG, base64-encoded — stands in for Beam's real QR image
/// (a reviewer can't scan a PromptPay QR against a live bank anyway; the
/// charge auto-confirms itself shortly after, see `DemoBackend`).
const demoQrImageBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
