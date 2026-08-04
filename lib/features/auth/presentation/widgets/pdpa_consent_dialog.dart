import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../../data/models/pdpa_policy.dart';

/// Used whenever `GET /legal/pdpa` isn't reachable — 404 until the backend
/// adds the endpoint (see CLAUDE.md), or any network failure. `version`
/// stays fixed so a consent recorded against this copy is distinguishable
/// from one recorded against a server-fetched version.
///
/// This is placeholder legal copy, not reviewed by counsel — replace before
/// shipping to real users.
const _fallbackPolicy = PdpaPolicy(
  version: 'bundled-2026-08-04',
  title: 'PDPA — พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
  sections: [
    PdpaSection(
      title: '1. ผู้ควบคุมข้อมูลส่วนบุคคล',
      body: 'บริษัท แคร์เมท จำกัด ("CareMate", "เรา") เป็นผู้ควบคุมข้อมูลส่วนบุคคลของท่านตามที่ระบุในนโยบายนี้ '
          'ในฐานะผู้ให้บริการแอปพลิเคชันจองบริการดูแลสุขภาพและรับส่งทางการแพทย์',
    ),
    PdpaSection(
      title: '2. ข้อมูลส่วนบุคคลที่เก็บรวบรวม',
      body: '(ก) ข้อมูลระบุตัวตน — ชื่อ-นามสกุล ชื่อเล่น เพศ วันเกิด รูปโปรไฟล์\n'
          '(ข) ข้อมูลติดต่อ — เบอร์โทรศัพท์ อีเมล ที่อยู่\n'
          '(ค) ข้อมูลตำแหน่งที่ตั้ง — พิกัดจุดรับ-ส่งสำหรับการจองแต่ละครั้ง\n'
          '(ง) ข้อมูลผู้รับบริการ/ญาติ — ชื่อ ความสัมพันธ์ ข้อมูลสุขภาพเบื้องต้นของบุคคลที่ท่านเพิ่มเข้าระบบเพื่อจองบริการแทน\n'
          '(จ) ข้อมูลการชำระเงิน — ประวัติการทำรายการและช่องทางชำระเงินที่เลือก (ไม่รวมข้อมูลบัตรที่ผู้ให้บริการชำระเงินภายนอกเป็นผู้เก็บ)\n'
          '(ฉ) ข้อมูลการใช้งาน — ประวัติการจอง สถานะการให้บริการ การสื่อสารกับผู้ให้บริการ',
    ),
    PdpaSection(
      title: '3. ข้อมูลส่วนบุคคลที่มีความอ่อนไหว',
      body: 'ข้อมูลสุขภาพของท่านหรือผู้รับบริการที่ท่านเพิ่มเข้าระบบถือเป็นข้อมูลอ่อนไหวตามมาตรา 26 '
          'ซึ่งต้องได้รับความยินยอมโดยชัดแจ้งแยกต่างหาก การกดยินยอมในหน้านี้ถือเป็นการให้ความยินยอมทั้งข้อมูลทั่วไปและข้อมูลสุขภาพที่จำเป็นต่อการจัดบริการดูแลสุขภาพให้ท่าน '
          'ท่านสามารถเลือกไม่กรอกข้อมูลสุขภาพที่ไม่จำเป็นได้ แต่อาจทำให้การจับคู่บริการไม่แม่นยำ',
    ),
    PdpaSection(
      title: '4. วัตถุประสงค์และฐานทางกฎหมายในการประมวลผล',
      body: '• เพื่อสร้างและยืนยันตัวตนบัญชีผู้ใช้ (ความจำเป็นเพื่อปฏิบัติตามสัญญา)\n'
          '• เพื่อจัดการการจอง จับคู่ผู้ให้บริการ และดำเนินการชำระเงิน (ความจำเป็นเพื่อปฏิบัติตามสัญญา)\n'
          '• เพื่อจัดบริการดูแลสุขภาพให้เหมาะสมกับผู้รับบริการ (ความยินยอมโดยชัดแจ้ง สำหรับข้อมูลสุขภาพ)\n'
          '• เพื่อติดต่อแจ้งสถานะบริการและแก้ไขปัญหาการใช้งาน (ประโยชน์โดยชอบด้วยกฎหมาย)',
    ),
    PdpaSection(
      title: '5. การเปิดเผยข้อมูลแก่บุคคลที่สาม',
      body: 'เราเปิดเผยข้อมูลเท่าที่จำเป็นแก่ผู้ให้บริการ (พาร์ทเนอร์/คนขับ/ผู้ดูแล) ที่ได้รับมอบหมายงานของท่านเท่านั้น '
          'รวมถึงผู้ให้บริการประมวลผลชำระเงินและผู้ให้บริการโครงสร้างพื้นฐานระบบ (เช่น ผู้ให้บริการคลาวด์) ภายใต้ข้อตกลงรักษาความลับ '
          'เราจะไม่ขายหรือเปิดเผยข้อมูลส่วนบุคคลของท่านแก่บุคคลภายนอกเพื่อวัตถุประสงค์ทางการตลาดโดยไม่ได้รับความยินยอมเพิ่มเติม',
    ),
    PdpaSection(
      title: '6. ระยะเวลาในการเก็บรักษาข้อมูล',
      body: 'ข้อมูลบัญชีผู้ใช้จะถูกเก็บไว้ตลอดระยะเวลาที่ท่านใช้งานแอป และอีกไม่เกิน 5 ปีหลังจากปิดบัญชี '
          'เพื่อวัตถุประสงค์ทางบัญชีและปฏิบัติตามกฎหมาย เว้นแต่ท่านร้องขอให้ลบข้อมูลก่อนกำหนดตามสิทธิของท่าน',
    ),
    PdpaSection(
      title: '7. มาตรการรักษาความปลอดภัยของข้อมูล',
      body: 'ข้อมูลของท่านถูกส่งผ่านการเชื่อมต่อที่เข้ารหัส (HTTPS) และจัดเก็บบนระบบที่จำกัดสิทธิ์การเข้าถึงเฉพาะเจ้าหน้าที่ที่เกี่ยวข้อง '
          'เราตรวจสอบและปรับปรุงมาตรการความปลอดภัยอย่างสม่ำเสมอเพื่อป้องกันการเข้าถึง ใช้ หรือเปิดเผยข้อมูลโดยไม่ได้รับอนุญาต',
    ),
    PdpaSection(
      title: '8. สิทธิของเจ้าของข้อมูลส่วนบุคคล',
      body: 'ท่านมีสิทธิ ดังนี้: เข้าถึงและขอสำเนาข้อมูล, แก้ไขข้อมูลให้ถูกต้อง, ลบหรือทำลายข้อมูล, ระงับการใช้ข้อมูลชั่วคราว, '
          'คัดค้านการประมวลผล, โอนย้ายข้อมูล, และถอนความยินยอมได้ทุกเมื่อผ่านหน้าโปรไฟล์ > การตั้งค่าความเป็นส่วนตัว '
          'การถอนความยินยอมอาจทำให้ไม่สามารถใช้บริการบางส่วนของแอปได้ ท่านสามารถร้องเรียนต่อสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคล (สคส.) ได้หากเห็นว่าเราไม่ปฏิบัติตามกฎหมาย',
    ),
    PdpaSection(
      title: '9. ช่องทางติดต่อ',
      body: 'หากมีข้อสงสัยเกี่ยวกับนโยบายนี้หรือต้องการใช้สิทธิของท่าน โปรดติดต่อเจ้าหน้าที่คุ้มครองข้อมูลส่วนบุคคล (DPO) '
          'ที่ privacy@caremate.app เราจะดำเนินการตามคำร้องขอภายใน 30 วัน',
    ),
    PdpaSection(
      title: '10. การเปลี่ยนแปลงนโยบาย',
      body: 'เราอาจปรับปรุงนโยบายนี้เป็นครั้งคราว หากมีการเปลี่ยนแปลงสาระสำคัญ เราจะแจ้งให้ท่านทราบและขอความยินยอมใหม่ก่อนใช้งานต่อ',
    ),
  ],
);

/// Shown right after the register form is validated, before the account is
/// actually created — the user must scroll through the full policy before
/// the accept action becomes available. Returns the accepted policy
/// `version` string, or `null` if the user declined/dismissed it.
class PdpaConsentDialog extends ConsumerStatefulWidget {
  const PdpaConsentDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PdpaConsentDialog()),
    );
  }

  @override
  ConsumerState<PdpaConsentDialog> createState() => _PdpaConsentDialogState();
}

class _PdpaConsentDialogState extends ConsumerState<PdpaConsentDialog> {
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _scrolledToEnd = false;
  bool _accepted = false;
  PdpaPolicy _policy = _fallbackPolicy;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPolicy();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    try {
      final policy = await ref.read(authRepositoryProvider).fetchPdpaPolicy();
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _loading = false;
      });
    } catch (_) {
      // Backend doesn't have GET /legal/pdpa yet (or the request otherwise
      // failed) — fall back to the bundled copy rather than blocking
      // registration on it.
      if (!mounted) return;
      setState(() => _loading = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfAlreadyAtEnd());
  }

  void _checkIfAlreadyAtEnd() {
    if (!_scrollController.hasClients || _scrolledToEnd) return;
    if (_scrollController.position.maxScrollExtent <= 0) {
      setState(() => _scrolledToEnd = true);
    }
  }

  void _onScroll() {
    if (_scrolledToEnd) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _scrolledToEnd = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ความยินยอมเก็บข้อมูลส่วนบุคคล'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      Text(
                        'โปรดอ่านนโยบายทั้งหมดจนจบก่อนกดยินยอม เพื่อให้ CareMate เก็บและใช้ข้อมูลของท่านตามที่ระบุด้านล่าง',
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_policy.title, style: textTheme.titleMedium),
                            for (var i = 0; i < _policy.sections.length; i++) ...[
                              const SizedBox(height: 18),
                              Text(_policy.sections[i].title, style: textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text(
                                _policy.sections[i].body,
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'จบนโยบายความเป็นส่วนตัว',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_scrolledToEnd)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.keyboard_double_arrow_down, size: 16, color: AppColors.warning),
                                const SizedBox(width: 6),
                                Text(
                                  'เลื่อนอ่านนโยบายให้ครบก่อนจึงจะกดยินยอมได้',
                                  style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
                                ),
                              ],
                            ),
                          ),
                        AppCard(
                          color: AppColors.surfaceAlt,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CheckboxListTile(
                            value: _accepted,
                            onChanged: _scrolledToEnd ? (v) => setState(() => _accepted = v ?? false) : null,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'ข้าพเจ้าได้อ่านและยินยอมให้ CareMate เก็บรวบรวม ใช้ และเปิดเผยข้อมูลส่วนบุคคล (รวมถึงข้อมูลสุขภาพ) ของข้าพเจ้าตามนโยบายข้างต้น',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'ยินยอมและดำเนินการต่อ',
                          icon: Icons.check_circle_outline,
                          onPressed:
                              (_scrolledToEnd && _accepted) ? () => Navigator.of(context).pop(_policy.version) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
