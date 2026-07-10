import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int _selectedServiceIndex = 0;
  int _selectedMemberIndex = 0;
  int _selectedTimeIndex = 1;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final _pickupController = TextEditingController(
    text: 'คอนโด CareMate Residence, ถนนสุขุมวิท',
  );

  final _destinationController = TextEditingController(
    text: 'โรงพยาบาลสมิติเวช สุขุมวิท',
  );

  final _noteController = TextEditingController(
    text: 'ผู้รับบริการเดินช้า กรุณาช่วยพยุงตอนขึ้นลงรถ',
  );

  final List<_BookingService> _services = const [
    _BookingService(
      title: 'รับ-ส่งพบแพทย์',
      subtitle: 'มีผู้ช่วยดูแลระหว่างเดินทาง',
      icon: Icons.local_taxi_rounded,
      color: Color(0xFF2CB7A0),
      baseFee: 450,
      distanceKm: 8.4,
      durationMinutes: 90,
      requiresDestination: true,
    ),
    _BookingService(
      title: 'ดูแลรายชั่วโมง',
      subtitle: 'ดูแลที่บ้านหรือคอนโด',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF5B8DEF),
      baseFee: 350,
      distanceKm: 0,
      durationMinutes: 120,
      requiresDestination: false,
    ),
    _BookingService(
      title: 'ซื้อยา / เวชภัณฑ์',
      subtitle: 'ให้พาร์ทเนอร์ช่วยซื้อและจัดส่ง',
      icon: Icons.medication_rounded,
      color: Color(0xFFFF9F43),
      baseFee: 180,
      distanceKm: 5.2,
      durationMinutes: 60,
      requiresDestination: true,
    ),
    _BookingService(
      title: 'พาไปทำธุระ',
      subtitle: 'ช่วยดูแลการเดินทางทั่วไป',
      icon: Icons.accessible_forward_rounded,
      color: Color(0xFFB56EFF),
      baseFee: 390,
      distanceKm: 7.1,
      durationMinutes: 80,
      requiresDestination: true,
    ),
  ];

  final List<_BookingMember> _members = const [
    _BookingMember(
      name: 'Gabel',
      fullName: 'ภัทรจาริน นภากาญจน์',
      relationship: 'ตัวเอง',
      age: 27,
      icon: Icons.person_rounded,
      color: Color(0xFF2CB7A0),
      note: 'ดูแลทั่วไป สามารถเดินทางเองได้',
    ),
    _BookingMember(
      name: 'พ่อ',
      fullName: 'สมชาย นภากาญจน์',
      relationship: 'บิดา',
      age: 64,
      icon: Icons.elderly_rounded,
      color: Color(0xFF5B8DEF),
      note: 'เดินช้า ต้องช่วยพยุงตอนขึ้นลงรถ',
    ),
    _BookingMember(
      name: 'แม่',
      fullName: 'สมหญิง นภากาญจน์',
      relationship: 'มารดา',
      age: 59,
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF9F43),
      note: 'มีทานยาประจำหลังอาหาร',
    ),
  ];

  final List<String> _timeSlots = const [
    '08:00',
    '09:30',
    '11:00',
    '13:00',
    '15:30',
    '18:00',
  ];

  _BookingService get _selectedService => _services[_selectedServiceIndex];

  _BookingMember get _selectedMember => _members[_selectedMemberIndex];

  String get _selectedTime => _timeSlots[_selectedTimeIndex];

  int get _estimatedFee {
    final service = _selectedService;
    final distanceFee = service.requiresDestination ? service.distanceKm * 28 : 0;
    return (service.baseFee + distanceFee).round();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = _selectedService;
    final member = _selectedMember;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
        actions: [
          IconButton(
            onPressed: _showMockInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildStepProgress(),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'เลือกบริการ',
            subtitle: 'เลือกประเภทบริการที่ต้องการให้ CareMate ช่วยดูแล',
            icon: Icons.medical_services_rounded,
          ),
          const SizedBox(height: 12),
          _buildServiceSelector(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'เลือกผู้รับบริการ',
            subtitle: 'เลือกว่าจะจองบริการให้ใคร',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildMemberSelector(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'วันและเวลา',
            subtitle: 'เลือกวันเวลาที่ต้องการรับบริการ',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 12),
          _buildDateTimeCard(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'สถานที่',
            subtitle: service.requiresDestination
                ? 'ระบุจุดรับและจุดหมายปลายทาง'
                : 'ระบุสถานที่ที่ต้องการให้ดูแล',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),
          _buildLocationCard(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'ข้อมูลเพิ่มเติม',
            subtitle: 'หมายเหตุสำหรับพาร์ทเนอร์ก่อนเริ่มงาน',
            icon: Icons.note_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildNoteCard(),
          const SizedBox(height: 24),
          _buildSummaryCard(service, member),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2CB7A0),
            Color(0xFF168B78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Mock Booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'จองบริการดูแลสุขภาพ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกบริการ ผู้รับบริการ วันเวลา และสถานที่ จากนั้นระบบจะสรุปราคาให้ก่อนยืนยัน',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              _MiniStep(
                number: '1',
                label: 'บริการ',
                active: true,
              ),
              _StepLine(active: true),
              _MiniStep(
                number: '2',
                label: 'เวลา',
                active: true,
              ),
              _StepLine(active: true),
              _MiniStep(
                number: '3',
                label: 'สถานที่',
                active: true,
              ),
              _StepLine(active: false),
              _MiniStep(
                number: '4',
                label: 'ยืนยัน',
                active: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.78,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final service = _services[index];
          final selected = _selectedServiceIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedServiceIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 178,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? service.color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? service.color : AppColors.border,
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: service.color.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : service.color.withValues(alpha: 0.12),
                    child: Icon(
                      service.icon,
                      color: selected ? Colors.white : service.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.86)
                          : AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberSelector() {
    return Column(
      children: _members.asMap().entries.map((entry) {
        final index = entry.key;
        final member = entry.value;
        final selected = _selectedMemberIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  _selectedMemberIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? member.color : AppColors.border,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: member.color.withValues(alpha: 0.14),
                      child: Icon(
                        member.icon,
                        color: member.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${member.relationship} • ${member.age} ปี',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            member.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('checked'),
                        color: member.color,
                      )
                          : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('unchecked'),
                        color: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'วันที่รับบริการ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                final selected = _selectedTimeIndex == index;

                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  label: Text(time),
                  onSelected: (_) {
                    setState(() {
                      _selectedTimeIndex = index;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final service = _selectedService;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _MockTextField(
            controller: _pickupController,
            label: service.requiresDestination ? 'จุดรับ' : 'สถานที่รับบริการ',
            icon: Icons.my_location_rounded,
          ),
          if (service.requiresDestination) ...[
            const SizedBox(height: 14),
            _MockTextField(
              controller: _destinationController,
              label: 'จุดหมายปลายทาง',
              icon: Icons.flag_rounded,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ระยะทางประมาณ ${service.distanceKm.toStringAsFixed(1)} กม. • ใช้เวลาประมาณ ${service.durationMinutes} นาที',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: TextField(
        controller: _noteController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'เช่น เดินช้า, ต้องใช้รถเข็น, แพ้อาหาร, ต้องช่วยถือของ',
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(_BookingService service, _BookingMember member) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'สรุปรายการจอง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Estimate',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'บริการ', value: service.title),
          _SummaryRow(label: 'ผู้รับบริการ', value: member.fullName),
          _SummaryRow(label: 'วันเวลา', value: '${_formatDate(_selectedDate)} $_selectedTime'),
          _SummaryRow(
            label: 'ระยะทาง',
            value: service.requiresDestination
                ? '${service.distanceKm.toStringAsFixed(1)} กม.'
                : '-',
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                'ยอดชำระโดยประมาณ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '฿$_estimatedFee',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
          ),
        ),
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
                  const Text(
                    'ราคาโดยประมาณ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '฿$_estimatedFee',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _showConfirmSheet,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('ยืนยันการจอง'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _showConfirmSheet() {
    final service = _selectedService;
    final member = _selectedMember;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ยืนยันรายการจอง',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ตรวจสอบข้อมูลก่อนสร้าง booking mock',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _ConfirmTile(
                icon: service.icon,
                color: service.color,
                title: service.title,
                subtitle: '฿$_estimatedFee • ${service.durationMinutes} นาที',
              ),
              _ConfirmTile(
                icon: member.icon,
                color: member.color,
                title: member.fullName,
                subtitle: '${member.relationship} • ${member.age} ปี',
              ),
              _ConfirmTile(
                icon: Icons.schedule_rounded,
                color: AppColors.primary,
                title: '${_formatDate(_selectedDate)} เวลา $_selectedTime',
                subtitle: 'เวลานัดหมายแบบ mock',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mock: สร้าง Booking สำเร็จ'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    context.go(AppRoutes.payment);
                  },
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('ยืนยันและไปชำระเงิน'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('กลับไปแก้ไข'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMockInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Mock'),
          content: const Text(
            'หน้านี้เป็น mock UI สำหรับทดสอบ flow การจอง ยังไม่ได้ต่อ API จริง ข้อมูลทั้งหมดเป็นข้อมูลจำลอง',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('เข้าใจแล้ว'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStep extends StatelessWidget {
  const _MiniStep({
    required this.number,
    required this.label,
    required this.active,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: active ? AppColors.primary : AppColors.border,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _MockTextField extends StatelessWidget {
  const _MockTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmTile extends StatelessWidget {
  const _ConfirmTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

class _BookingService {
  const _BookingService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.baseFee,
    required this.distanceKm,
    required this.durationMinutes,
    required this.requiresDestination,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int baseFee;
  final double distanceKm;
  final int durationMinutes;
  final bool requiresDestination;
}

class _BookingMember {
  const _BookingMember({
    required this.name,
    required this.fullName,
    required this.relationship,
    required this.age,
    required this.icon,
    required this.color,
    required this.note,
  });

  final String name;
  final String fullName;
  final String relationship;
  final int age;
  final IconData icon;
  final Color color;
  final String note;
}