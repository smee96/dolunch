import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api.dart';
import '../../../core/utils/format.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  int _step = 0;

  // Step 1 — 메뉴
  final _titleCtrl = TextEditingController();
  final _menuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Step 2 — 장소
  final _placeCtrl = TextEditingController();

  // Step 3 — 인원/일정
  int _capacity = 4;
  DateTime? _date;
  TimeOfDay? _time;

  // Step 4 — 가격
  int _pricePerPerson = 0;

  bool get _canNext => switch (_step) {
    0 => _titleCtrl.text.isNotEmpty && _menuCtrl.text.isNotEmpty,
    1 => _placeCtrl.text.isNotEmpty,
    2 => _date != null && _time != null,
    3 => _pricePerPerson >= 10000,
    _ => false,
  };

  String get _meetAt {
    if (_date == null || _time == null) return '';
    final dt = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    return dt.toUtc().toIso8601String();
  }

  Future<void> _submit() async {
    final notifier = ref.read(createRoomProvider.notifier);
    final id = await notifier.create(
      title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
      menu: _menuCtrl.text.trim(), placeName: _placeCtrl.text.trim(),
      meetAt: _meetAt, capacity: _capacity, pricePerPerson: _pricePerPerson,
    );
    if (id != null && mounted) setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          _StepHeader(step: _step, onBack: _step == 0 ? () => context.pop() : () => setState(() => _step--)),
          if (_step < 4) _ProgressBar(step: _step),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: switch (_step) {
              0 => _StepMenu(titleCtrl: _titleCtrl, menuCtrl: _menuCtrl, descCtrl: _descCtrl, onChanged: () => setState(() {})),
              1 => _StepPlace(placeCtrl: _placeCtrl, onChanged: () => setState(() {})),
              2 => _StepSchedule(capacity: _capacity, date: _date, time: _time,
                  onCapacity: (v) => setState(() => _capacity = v),
                  onDate: (d) => setState(() => _date = d),
                  onTime: (t) => setState(() => _time = t)),
              3 => _StepPrice(price: _pricePerPerson, onPrice: (p) => setState(() => _pricePerPerson = p)),
              _ => const SizedBox.shrink(),
            },
          )),
          if (_step == 4)
            _SuccessScreen(onDone: () { context.go('/rooms'); })
          else
            _BottomCTA(
              label: _step == 3 ? '모임 열기' : '다음',
              enabled: _canNext,
              loading: ref.watch(createRoomProvider).isLoading,
              onTap: _step == 3 ? _submit : () => setState(() => _step++),
            ),
        ]),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  const _StepHeader({required this.step, required this.onBack});

  static const _titles = ['메뉴 정하기', '장소 정하기', '인원·일정', '가격 설정'];

  @override
  Widget build(BuildContext context) {
    if (step == 4) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: onBack),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text('STEP ${step + 1} / 4', style: const TextStyle(
            fontFamily: 'monospace', fontSize: 11, letterSpacing: 3, color: AppColors.sub,
          )),
          const SizedBox(height: 2),
          Text(_titles[step], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ])),
        const SizedBox(width: 44),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: i <= step ? const LinearGradient(colors: [AppColors.accent, AppColors.primary]) : null,
            color: i > step ? AppColors.line : null,
          ),
        ),
      ))),
    );
  }
}

// ─── Step 1 ───────────────────────────────────────────────────────────────────
class _StepMenu extends StatelessWidget {
  final TextEditingController titleCtrl, menuCtrl, descCtrl;
  final VoidCallback onChanged;
  const _StepMenu({required this.titleCtrl, required this.menuCtrl, required this.descCtrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _FieldLabel('모임 제목'),
      TextField(controller: titleCtrl, onChanged: (_) => onChanged(), decoration: const InputDecoration(hintText: '예: 성수 브런치 다이닝')),
      const SizedBox(height: 16),
      _FieldLabel('메뉴'),
      TextField(controller: menuCtrl, onChanged: (_) => onChanged(), decoration: const InputDecoration(hintText: '예: 트러플 크림 파스타')),
      const SizedBox(height: 16),
      _FieldLabel('한 줄 소개'),
      TextField(controller: descCtrl, onChanged: (_) => onChanged(), maxLines: 3,
        decoration: const InputDecoration(hintText: '모임을 소개해 주세요', alignLabelWithHint: true)),
      const SizedBox(height: 32),
    ]);
  }
}

// ─── Step 2 ───────────────────────────────────────────────────────────────────
class _StepPlace extends StatelessWidget {
  final TextEditingController placeCtrl;
  final VoidCallback onChanged;
  const _StepPlace({required this.placeCtrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _FieldLabel('식당/장소'),
      TextField(controller: placeCtrl, onChanged: (_) => onChanged(), decoration: const InputDecoration(hintText: '예: 성수 · 도산분식 본점')),
      const SizedBox(height: 16),
      Container(height: 160, decoration: BoxDecoration(
        color: AppColors.base, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ), child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_on, size: 32, color: AppColors.primary),
        SizedBox(height: 8),
        Text('지도 연동 예정', style: TextStyle(color: AppColors.sub, fontSize: 13)),
      ]))),
      const SizedBox(height: 32),
    ]);
  }
}

// ─── Step 3 ───────────────────────────────────────────────────────────────────
class _StepSchedule extends StatelessWidget {
  final int capacity;
  final DateTime? date;
  final TimeOfDay? time;
  final ValueChanged<int> onCapacity;
  final ValueChanged<DateTime?> onDate;
  final ValueChanged<TimeOfDay?> onTime;

  const _StepSchedule({
    required this.capacity, required this.date, required this.time,
    required this.onCapacity, required this.onDate, required this.onTime,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _FieldLabel('인원 (2–12명)'),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _StepBtn(icon: Icons.remove, onTap: () { if (capacity > 2) onCapacity(capacity - 1); }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text('$capacity', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ),
        _StepBtn(icon: Icons.add, onTap: () { if (capacity < 12) onCapacity(capacity + 1); }),
      ]),
      const SizedBox(height: 28),
      _FieldLabel('날짜'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        _Chip(label: '오늘', selected: date?.day == today.day, onTap: () => onDate(today)),
        _Chip(label: '내일', selected: date?.day == tomorrow.day, onTap: () => onDate(tomorrow)),
        _Chip(label: '날짜 선택', selected: date != null && date!.day != today.day && date!.day != tomorrow.day,
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: today,
              firstDate: today, lastDate: today.add(const Duration(days: 90)));
            if (d != null) onDate(d);
          }),
      ]),
      const SizedBox(height: 24),
      _FieldLabel('시간'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in ['11:30', '12:00', '12:30', '13:00', '18:00', '19:00'])
          _Chip(label: t, selected: time != null && '${time!.hour.toString().padLeft(2,'0')}:${time!.minute.toString().padLeft(2,'0')}' == t,
            onTap: () { final parts = t.split(':'); onTime(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))); }),
        _Chip(label: '직접 선택', selected: false,
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
            if (t != null) onTime(t);
          }),
      ]),
      const SizedBox(height: 32),
    ]);
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line, width: 1.5)),
      child: Icon(icon, color: AppColors.ink, size: 20),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.ink,
      )),
    ),
  );
}

// ─── Step 4 ───────────────────────────────────────────────────────────────────
class _StepPrice extends StatelessWidget {
  final int price;
  final ValueChanged<int> onPrice;
  const _StepPrice({required this.price, required this.onPrice});

  @override
  Widget build(BuildContext context) {
    final deposit = ApiConstants.calcDeposit(price);
    final fee = ApiConstants.calcPlatformFee(price);
    final revenue = ApiConstants.calcHostRevenue(price);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _FieldLabel('1인 참가 금액'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in [30000, 50000, 100000, 200000, 300000, 500000])
          _Chip(label: wonStr(p), selected: price == p, onTap: () => onPrice(p)),
      ]),
      const SizedBox(height: 16),
      TextField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: '직접 입력 (최소 10,000원)', suffixText: '원'),
        onChanged: (v) { final n = int.tryParse(v.replaceAll(',', '')); if (n != null) onPrice(n); },
      ),

      if (price >= 10000) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF6F0), Color(0xFFFFF0F5)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(children: [
            const Text('보증금은 이렇게 작동해요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 16),
            _InfoRow('게스트 보증금 (20%)', wonStr(deposit), AppColors.primary),
            const SizedBox(height: 8),
            _InfoRow('플랫폼 수수료 (30%)', wonStr(fee), AppColors.sub),
            const SizedBox(height: 8),
            _InfoRow('호스트 정산액 (70%)', wonStr(revenue), AppColors.success),
            const Divider(height: 20, color: AppColors.line),
            const _BulletText('① 게스트가 지원 시 보증금(20%) 선결제'),
            const SizedBox(height: 6),
            const _BulletText('② 정상 참석 시 보증금 전액 환불'),
            const SizedBox(height: 6),
            const _BulletText('③ 노쇼 시 보증금 차감'),
          ]),
        ),
      ],
      const SizedBox(height: 32),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ],
  );
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('• ', style: TextStyle(color: AppColors.sub, fontSize: 12)),
    Expanded(child: Text(text, style: const TextStyle(color: AppColors.sub, fontSize: 12, height: 1.5))),
  ]);
}

// ─── 성공 화면 ────────────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessScreen({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.glamGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              const Text('모임이 열렸어요!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              Text('숏츠를 올리면 더 많은 게스트에게\n모임을 알릴 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.85), height: 1.6)),
              const SizedBox(height: 48),
              SizedBox(width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onDone,
                  child: const Text('내 모임에서 보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/upload/reel'),
                child: const Text('숏츠 올리기', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── 공통 위젯 ────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
  );
}

class _BottomCTA extends StatelessWidget {
  final String label;
  final bool enabled, loading;
  final VoidCallback onTap;
  const _BottomCTA({required this.label, required this.enabled, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line.withOpacity(0.5))),
      ),
      child: SizedBox(
        width: double.infinity, height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? const LinearGradient(colors: [AppColors.accent, AppColors.primary, AppColors.deep]) : null,
            color: enabled ? null : AppColors.line,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled ? [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 22, offset: const Offset(0, 10))] : null,
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: (enabled && !loading) ? onTap : null,
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
