import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/back_circle_button.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/section_header.dart';

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

// Content grounded in this app's actual, current behavior — not generic
// filler. See booking_repository.dart / booking.dart / app_config.dart for
// the specifics each answer below cites.
final _faqs = [
  const _Faq(
    'จองบริการอย่างไร',
    'กดปุ่ม "จองบริการ" จากหน้าหลัก แล้วทำตามขั้นตอนทั้ง 5 ขั้นตอน ได้แก่ '
        '1) เลือกประเภทบริการ 2) เลือกวันและช่วงเวลาที่ต้องการ 3) เลือกผู้รับบริการ '
        '(ตัวคุณเองหรือสมาชิกที่ดูแล) 4) เลือกที่อยู่รับบริการ (และปลายทาง '
        'สำหรับบริการเดินทาง) และ 5) ตรวจสอบรายละเอียดและยืนยันการจอง '
        'จากนั้นระบบจะพาไปหน้าชำระเงินโดยอัตโนมัติ',
  ),
  const _Faq(
    'ชำระเงินด้วยวิธีไหนได้บ้าง',
    'ปัจจุบันรองรับการชำระเงินผ่าน PromptPay QR เท่านั้น หลังยืนยันการจอง '
        'ระบบจะสร้าง QR code ให้สแกนจากแอปธนาคารของคุณ QR แต่ละใบมีเวลาหมดอายุ '
        'จำกัด หากหมดอายุก่อนชำระ จะต้องทำรายการจองใหม่อีกครั้ง',
  ),
  const _Faq(
    'ยกเลิกการจองได้ไหม เงื่อนไขอย่างไร',
    'ยกเลิกได้ด้วยตนเองในแอป ตราบใดที่สถานะการจองยังเป็น "รอชำระเงิน", '
        '"กำลังหาผู้ดูแล" หรือ "จับคู่แล้ว" เท่านั้น เมื่อสถานะเปลี่ยนเป็น '
        '"กำลังดำเนินการ" (ผู้ดูแล/คนขับออกปฏิบัติงานแล้ว) จะไม่สามารถยกเลิกเองได้ '
        'ในแอป ต้องติดต่อทีมช่วยเหลือของเราแทน หากยกเลิกก่อนชำระเงิน จะไม่มีค่าใช้จ่ายใดๆ',
  ),
  const _Faq(
    'ติดตามสถานะการจองได้อย่างไร',
    'หลังชำระเงินสำเร็จ แอปจะแสดงหน้าติดตามสถานะโดยอัตโนมัติ '
        'และจะอัปเดตสถานะให้เป็นระยะจนกว่าจะมีผู้ดูแลรับงาน (ระบบยังไม่มีการแจ้งเตือนแบบ '
        'push จากเซิร์ฟเวอร์ จึงต้องเปิดหน้านี้ค้างไว้หรือกลับมาเช็กเป็นระยะ) '
        'หากรอนานเกิน 10 นาทีโดยยังไม่มีผู้รับงาน แอปจะแสดงข้อความแจ้งเตือนว่าอาจล่าช้ากว่าปกติ',
  ),
  const _Faq(
    'เพิ่มสมาชิกในความดูแลได้กี่คน',
    'เพิ่มสมาชิกที่ดูแลได้สูงสุด ${AppConfig.maxRelatives} คนต่อบัญชี '
        'สามารถจัดการรายชื่อ แก้ไขข้อมูล และเลือกใช้งานตอนจองบริการแทนตัวเองได้ '
        'จากเมนู "สมาชิกที่ดูแล" ในหน้าโปรไฟล์',
  ),
  const _Faq(
    'เข้าสู่ระบบด้วยอะไร ต้องมีรหัสผ่านไหม',
    'แอปนี้เข้าสู่ระบบด้วยเบอร์โทรศัพท์เท่านั้น ไม่ต้องตั้งรหัสผ่าน '
        'ระบบจะยืนยันตัวตนผ่านการส่งรหัส OTP ไปยังเบอร์โทรที่ลงทะเบียนไว้ทุกครั้งที่เข้าสู่ระบบ',
  ),
  const _Faq(
    'ข้อมูลของฉันปลอดภัยไหม',
    'ข้อมูลส่วนบุคคลของคุณถูกจัดเก็บและใช้งานตามนโยบายความเป็นส่วนตัว (PDPA) '
        'ที่คุณให้ความยินยอมไว้ตอนสมัครสมาชิก คุณสามารถตรวจสอบและแก้ไขข้อมูลส่วนตัว '
        'ข้อมูลสุขภาพ และที่อยู่ได้เองทุกเมื่อจากเมนูโปรไฟล์ หากต้องการลบข้อมูลหรือมีข้อสงสัย '
        'เพิ่มเติมเกี่ยวกับการใช้ข้อมูล สามารถติดต่อทีมงานได้ตามช่องทางด้านล่าง',
  ),
  const _Faq(
    'ราคาบริการคิดอย่างไร',
    'ค่าบริการคำนวณตามประเภทบริการ ระยะเวลา และระยะทาง (สำหรับบริการเดินทาง) '
        'โดยระบบจะแสดงยอดรวมทั้งหมดให้ตรวจสอบก่อนยืนยันการจองและก่อนชำระเงินเสมอ '
        'ไม่มีค่าใช้จ่ายแอบแฝงเพิ่มเติมภายหลัง',
  ),
  const _Faq(
    'จองล่วงหน้าได้กี่ชั่วโมง หรือจองแบบเร่งด่วนได้ไหม',
    'สามารถเลือกวันและเวลาที่ต้องการใช้บริการได้อย่างอิสระในขั้นตอนที่ 2 ของการจอง '
        'ทั้งนี้เวลาที่หาผู้ดูแลได้จริงขึ้นอยู่กับความพร้อมของผู้ดูแลในพื้นที่ ณ ช่วงเวลานั้นๆ '
        'แนะนำให้จองล่วงหน้าหากเป็นไปได้เพื่อเพิ่มโอกาสจับคู่สำเร็จ',
  ),
];

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@caremate.app',
      query: 'subject=สอบถามข้อมูลการใช้งาน CareMate',
    );

    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบแอปสำหรับส่งอีเมลบนอุปกรณ์นี้')),
      );
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '021234567');
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโทรออกจากอุปกรณ์นี้ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(height: 260),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 68,
              20,
              32,
            ),
            children: [
              AppCard(
                glass: true,
                child: Row(
                  children: [
                    const CircleIconAvatar(
                      icon: Icons.help_outline_rounded,
                      color: AppColors.primary,
                      radius: 26,
                      filled: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('คำถามที่พบบ่อย', style: textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'รวมคำตอบเกี่ยวกับการจอง การชำระเงิน และการใช้งานแอป',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader(
                title: 'คำถามที่พบบ่อย',
                icon: Icons.quiz_outlined,
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: Column(
                    children: [
                      for (var i = 0; i < _faqs.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          expandedAlignment: Alignment.centerLeft,
                          title: Text(
                            _faqs[i].question,
                            style: textTheme.titleSmall,
                          ),
                          children: [
                            Text(
                              _faqs[i].answer,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'ติดต่อเรา',
                subtitle: 'ยังหาคำตอบไม่เจอ? ทีมงานพร้อมช่วยเหลือ',
                icon: Icons.support_agent_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => _launchEmail(context),
                child: Row(
                  children: [
                    const CircleIconAvatar(
                      icon: Icons.email_outlined,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('อีเมล', style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            'support@caremate.app',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => _launchPhone(context),
                child: Row(
                  children: [
                    const CircleIconAvatar(
                      icon: Icons.phone_outlined,
                      color: AppColors.serviceHomeCare,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('โทรหาเรา', style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text('02-123-4567', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'เวลาทำการทีมช่วยเหลือ: จันทร์–ศุกร์ 08:30–18:00 น.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          // Painted after the ListView so it stays on top for hit-testing.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 20,
            child: BackCircleButton(
              onTap: () => context.popBack(AppRoutes.profile),
            ),
          ),
        ],
      ),
    );
  }
}
