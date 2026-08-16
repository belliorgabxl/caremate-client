import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/referral_repository.dart';

class ReferralPage extends ConsumerStatefulWidget {
  const ReferralPage({super.key});

  @override
  ConsumerState<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends ConsumerState<ReferralPage> {
  bool _isLoading = true;
  String? _loadError;
  ReferralInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final info = await ref.read(referralRepositoryProvider).getReferral();
      if (!mounted) return;
      setState(() {
        _info = info;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('คัดลอกรหัสเรียบร้อยแล้ว')));
  }

  Future<void> _shareCode(String code) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'มาลองใช้ CareMate สิ! สมัครสมาชิกและใส่รหัสชวนเพื่อนของฉัน "$code" '
            'ตอนสมัครได้เลย',
        subject: 'ชวนเพื่อนใช้ CareMate',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ชวนเพื่อน'),
        leading: BackButton(onPressed: () => context.goBack(AppRoutes.profile)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(height: 320),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + 68,
                    20,
                    32,
                  ),
                  children: [
                    EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'โหลดข้อมูลไม่สำเร็จ',
                      message: _loadError!,
                      action: PrimaryButton(
                        label: 'ลองอีกครั้ง',
                        icon: Icons.refresh_rounded,
                        expanded: false,
                        onPressed: _load,
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.paddingOf(context).top + 68,
                      20,
                      32,
                    ),
                    children: [
                      AppCard(
                        glass: true,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const CircleIconAvatar(
                              icon: Icons.card_giftcard_rounded,
                              color: AppColors.serviceErrand,
                              radius: 30,
                              filled: true,
                              iconSize: 32,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'ชวนเพื่อนมาใช้ CareMate',
                              style: textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'แชร์รหัสของคุณให้เพื่อนกรอกตอนสมัครสมาชิก',
                              style: textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.serviceErrand.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                (_info?.code.isNotEmpty == true)
                                    ? _info!.code
                                    : '-',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: AppColors.serviceErrand,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _info == null
                                        ? null
                                        : () => _copyCode(_info!.code),
                                    icon: const Icon(Icons.copy_rounded),
                                    label: const Text('คัดลอก'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _info == null
                                        ? null
                                        : () => _shareCode(_info!.code),
                                    icon: const Icon(Icons.share_rounded),
                                    label: const Text('แชร์รหัสชวนเพื่อน'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        child: Row(
                          children: [
                            const CircleIconAvatar(
                              icon: Icons.diversity_3_rounded,
                              color: AppColors.serviceHomeCare,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('เพื่อนที่ชวนมาแล้ว', style: textTheme.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_info?.totalReferred ?? 0} คน',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
