import 'package:intl/intl.dart';

final _wonFmt = NumberFormat('#,###', 'ko_KR');
final _dateFmt = DateFormat('M월 d일 HH:mm', 'ko_KR');
final _dateOnlyFmt = DateFormat('M월 d일', 'ko_KR');

String wonStr(int amount) => '${_wonFmt.format(amount)}원';

String kstDateTime(String iso) {
  final dt = DateTime.parse(iso).toLocal();
  return _dateFmt.format(dt);
}

String kstDate(String iso) {
  final dt = DateTime.parse(iso).toLocal();
  return _dateOnlyFmt.format(dt);
}
