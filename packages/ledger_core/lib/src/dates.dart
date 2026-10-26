/// 日期工具。全部使用本地时区、正午 12:00 构造，避开夏令时/跨日边界。
library;

import 'js_compat.dart';

/// 两位补零。
String pad2(int n) => (n < 10 ? '0' : '') + n.toString();

/// JS `new Date(...).toISOString()` 的等价实现（毫秒精度、UTC、Z 结尾）。
String iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${pad2(date.month)}-${pad2(date.day)}';

/// 与 JS `date.toISOString()` 等价（UTC、毫秒精度、Z 结尾）。
String toISOString(DateTime date) {
  final d = date.toUtc();
  return '${d.year.toString().padLeft(4, '0')}-${pad2(d.month)}-${pad2(d.day)}'
      'T${pad2(d.hour)}:${pad2(d.minute)}:${pad2(d.second)}'
      '.${d.millisecond.toString().padLeft(3, '0')}Z';
}

/// 当前时间（对应 JS `new Date().toISOString()`）。
String nowISO() => toISOString(DateTime.now());

/// 解析 `YYYY-MM-DD`（缺失/非法部分按 JS 的 `||` 规则回退）。对应 JS `parseISO`。
DateTime parseISO(String? str) {
  final parts = (str ?? '').split('-').map((e) => double.tryParse(e.trim()) ?? 0).toList();
  double at(int i) => i < parts.length ? parts[i] : 0;
  final y = at(0);
  final m = at(1);
  final d = at(2);
  return DateTime(
    y == 0 || y.isNaN ? 1970 : y.truncate(),
    m == 0 || m.isNaN ? 1 : m.truncate(),
    d == 0 || d.isNaN ? 1 : d.truncate(),
    12,
  );
}

/// 今天（本地）。对应 JS `todayISO`。
String todayISO() => iso(DateTime.now());

/// 当月 `YYYY-MM`。对应 JS `thisMonthKey`。
String thisMonthKey() => todayISO().substring(0, 7);

/// 账单日期取 `YYYY-MM`。对应 JS `monthKeyOf`。
String monthKeyOf(String? day) {
  final s = day ?? '';
  return s.length <= 7 ? s : s.substring(0, 7);
}

/// 某年某月（1 起）的天数。对应 JS `daysInMonth`。
int daysInMonth(int year, int month1) => DateTime(year, month1, 0).day;

/// 月份第一天。对应 JS `monthStart`。
String monthStart(String key) => '$key-01';

/// 月份最后一天。对应 JS `monthEnd`。
String monthEnd(String key) {
  final parts = key.split('-');
  final y = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return '$key-${pad2(daysInMonth(y, m))}';
}

/// 日期加减天数。对应 JS `addDaysISO`。
String addDaysISO(String day, int delta) {
  final d = parseISO(day);
  return iso(DateTime(d.year, d.month, d.day + delta, 12));
}

/// 月份加减，返回 `YYYY-MM`。对应 JS `addMonthsKey`。
String addMonthsKey(String key, int delta) {
  final parts = key.split('-');
  final y = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  // JS 的月份是 0 起：new Date(y, m - 1 + delta, 1, 12)；Dart 是 1 起。
  final d = DateTime(y, m + delta, 1, 12);
  return '${d.year}-${pad2(d.month)}';
}

/// JS `getDay()`：0 = 周日 … 6 = 周六。对应 JS `weekdayIndex`。
int weekdayIndex(String? day) => parseISO(day).weekday % 7;

/// 中文星期。对应 JS `weekdayCN`。
String weekdayCN(String? day) => weekCN[weekdayIndex(day)];

/// `2026年10月`。对应 JS `monthLabel`。
String monthLabel(String key) {
  final parts = key.split('-');
  final y = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return '$y年$m月';
}

/// `10月`。对应 JS `shortMonthLabel`。
String shortMonthLabel(String key) {
  final parts = key.split('-');
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return '$m月';
}

/// `10月5日`。对应 JS `dateLabel`。
String dateLabel(String? day) {
  final d = parseISO(day);
  return '${d.month}月${d.day}日';
}

/// `2026年10月5日`。对应 JS `fullDateLabel`。
String fullDateLabel(String? day) {
  final d = parseISO(day);
  return '${d.year}年${d.month}月${d.day}日';
}

/// 今天/昨天/前天。对应 JS `relativeDay`。
String relativeDay(String? day) {
  final t = todayISO();
  if (day == t) return '今天';
  if (day == addDaysISO(t, -1)) return '昨天';
  if (day == addDaysISO(t, -2)) return '前天';
  return '';
}

/// 某月每天 `YYYY-MM-DD`。对应 JS `monthDays`。
List<String> monthDays(String key) {
  final parts = key.split('-');
  final y = int.tryParse(parts.isNotEmpty ? parts[0] : '');
  final m = int.tryParse(parts.length > 1 ? parts[1] : '');
  if (y == null || m == null) return <String>[];
  final n = daysInMonth(y, m);
  return <String>[for (var i = 1; i <= n; i++) '$key-${pad2(i)}'];
}

/// 两个月份相差几个月。对应 JS `monthsBetween`。
int monthsBetween(String startKey, String endKey) {
  final s = startKey.split('-');
  final e = endKey.split('-');
  final sy = int.tryParse(s.isNotEmpty ? s[0] : '') ?? 0;
  final sm = int.tryParse(s.length > 1 ? s[1] : '') ?? 0;
  final ey = int.tryParse(e.isNotEmpty ? e[0] : '') ?? 0;
  final em = int.tryParse(e.length > 1 ? e[1] : '') ?? 0;
  return (ey - sy) * 12 + (em - sm);
}

/// `normalizeBillDate` 的返回值。
class DateInfo {
  const DateInfo({required this.date, required this.time});

  /// `YYYY-MM-DD`。
  final String date;

  /// `HH:MM`，字符串输入未带时间时为空串。
  final String time;

  @override
  bool operator ==(Object other) =>
      other is DateInfo && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => 'DateInfo(date: $date, time: $time)';
}

/// Excel 序列号 / 多种日期字符串 → 账单日期。对应 JS `normalizeBillDate`。
DateInfo? normalizeBillDate(Object? value) {
  if (value is num && value > 0) {
    final whole = value.floor();
    final frac = value - whole;
    final ms = jsRound((whole - 25569) * 86400 * 1000 + jsRound(frac * 86400) * 1000);
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return DateInfo(
      date: '${d.year.toString().padLeft(4, '0')}-${pad2(d.month)}-${pad2(d.day)}',
      time: '${pad2(d.hour)}:${pad2(d.minute)}',
    );
  }
  var text = jsString(value ?? '').trim();
  if (text.isEmpty) return null;
  text = text
      .replaceAll(RegExp('[年月]'), '-')
      .replaceAll('日', '')
      .replaceAll(RegExp(r'[./]'), '-');
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{1,2}))?').firstMatch(text);
  if (m == null) return null;
  final month = int.parse(m[2]!);
  final day = int.parse(m[3]!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final hour = m[4];
  final minute = m[5];
  return DateInfo(
    date: '${m[1]}-${pad2(month)}-${pad2(day)}',
    time: hour != null ? '${pad2(int.parse(hour))}:${pad2(minute == null ? 0 : int.parse(minute))}' : '',
  );
}

/// 与 JS `WEEK_CN` 一致。
const List<String> weekCN = <String>['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
