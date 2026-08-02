import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/payment.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../booking/data/booking_repository.dart';
import '../../data/payment_repository.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isLoading = true;
  bool _canConfirm = false;
  bool _isConfirming = false;

  Booking? _booking;
  Payment? _payment;
  List<PaymentMethod> _methods = const [];
  String? _qrPayload;

  Timer? _unlockTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final bookingRepo = ref.read(bookingRepositoryProvider);
    final paymentRepo = ref.read(paymentRepositoryProvider);

    final pending = await bookingRepo.getPendingPayment();
    final methods = await paymentRepo.getMethods();

    Payment? payment;
    if (pending != null && pending.$2.id.isNotEmpty) {
      payment = await paymentRepo.getById(pending.$2.id);
    }

    if (!mounted) return;
    setState(() {
      _booking = pending?.$1;
      _payment = payment;
      _methods = methods;
      _isLoading = false;
    });

    if (payment != null) {
      _startTimers(payment);
      await _loadQrIfNeeded(payment);
    }
  }

  Future<void> _loadQrIfNeeded(Payment payment) async {
    final method = _selectedMethod;
    if (method?.slug != 'qr_promptpay') return;

    final payload = ref.read(paymentRepositoryProvider).getPromptPayQrPayload(amount: payment.totalAmount);

    if (!mounted) return;
    setState(() => _qrPayload = payload);
  }

  void _startTimers(Payment payment) {
    _canConfirm = false;
    _unlockTimer?.cancel();
    _unlockTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _canConfirm = true);
    });

    _countdownTimer?.cancel();
    _updateRemaining(payment);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining(payment);
    });
  }

  void _updateRemaining(Payment payment) {
    final expiredAt = payment.expiredAt;
    if (expiredAt == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final remaining = expiredAt.difference(DateTime.now());
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
  }

  String get _countdownLabel {
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  PaymentMethod? get _selectedMethod {
    final payment = _payment;
    if (payment == null || _methods.isEmpty) return null;
    for (final method in _methods) {
      if (method.id == payment.paymentMethodId) return method;
    }
    return _methods.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ชำระเงิน')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;
    final payment = _payment;

    if (booking == null || payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ชำระเงิน')),
        body: const Center(child: Text('ไม่มีรายการที่รอชำระเงิน')),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final method = _selectedMethod;

    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      bottomNavigationBar: _buildBottomBar(payment),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('สรุปรายการจอง', style: textTheme.titleMedium)),
                    StatusBadge(text: payment.status.label, color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 16),
                _SummaryRow(label: 'บริการ', value: booking.serviceTitle),
                _SummaryRow(label: 'ผู้รับบริการ', value: booking.memberName),
                _SummaryRow(label: 'อ้างอิง', value: booking.reference),
                const Divider(height: 24),
                Row(
                  children: [
                    Text(
                      'ยอดชำระ',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '฿${payment.totalAmount.toStringAsFixed(0)}',
                      style: textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (method?.slug == 'qr_promptpay') ...[
            const SectionHeader(
              title: 'สแกน QR เพื่อชำระเงิน',
              subtitle: 'เปิดแอปธนาคารแล้วสแกน QR นี้',
              icon: Icons.qr_code_rounded,
            ),
            const SizedBox(height: 12),
            _PromptPayQrCard(
              payload: _qrPayload,
              reference: payment.reference,
              countdownLabel: _countdownLabel,
            ),
          ] else if (method != null) ...[
            const SectionHeader(
              title: 'วิธีชำระเงิน',
              icon: Icons.wallet_rounded,
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  CircleIconAvatar(icon: method.icon, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(method.title, style: textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(method.subtitle, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(Payment payment) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยอดชำระ', style: textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text('฿${payment.totalAmount.toStringAsFixed(0)}', style: textTheme.headlineSmall),
                ],
              ),
            ),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: _canConfirm ? 'ฉันชำระเงินแล้ว' : 'กรุณาสแกน QR ก่อน',
                icon: Icons.lock_rounded,
                isLoading: _isConfirming,
                onPressed: (_canConfirm && !_isConfirming) ? () => _confirmPayment(payment) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(Payment payment) async {
    setState(() => _isConfirming = true);

    await ref.read(paymentRepositoryProvider).confirm(bookingId: payment.bookingId, paymentId: payment.id);
    ref.read(bookingRepositoryProvider).clearPendingPayment();

    if (!mounted) return;
    setState(() => _isConfirming = false);
    _showSuccessSheet(_booking!);
  }

  void _showSuccessSheet(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleIconAvatar(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                radius: 42,
                filled: true,
                iconSize: 44,
              ),
              const SizedBox(height: 16),
              Text('ชำระเงินสำเร็จ', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'ระบบได้บันทึกรายการชำระเงินเรียบร้อยแล้ว',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'ติดตามสถานะการจอง',
                icon: Icons.track_changes_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.bookingStatusPath(booking.id), extra: booking);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.home);
                  },
                  child: const Text('กลับหน้าหลัก'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromptPayQrCard extends StatelessWidget {
  const _PromptPayQrCard({required this.payload, required this.reference, required this.countdownLabel});

  final String? payload;
  final String reference;
  final String countdownLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasPayload = payload != null && payload!.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: hasPayload
                ? QrImageView(data: payload!, backgroundColor: AppColors.surfaceAlt)
                : const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text('อ้างอิง: $reference', style: textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Text(
                'QR หมดอายุใน $countdownLabel นาที',
                style: textTheme.bodySmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

        return Padding(
    padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
