/// 农历 / 节气 / 节日标签。
///
/// Web 版依赖 `Intl.DateTimeFormat('zh-CN-u-ca-chinese')`；Dart 没有内置农历，
/// 这里用 `lunar_table.dart`（由同一份 ICU 数据生成，1900–2100）实现。
library;

import 'dates.dart';
import 'lunar_table.dart';

/// 节气名（按月份成对排列）。对应 JS `SOLAR_TERM_NAMES`。
const List<String> _solarTermNames = <String>[
  '小寒', '大寒', '立春', '雨水', '惊蛰', '春分', '清明', '谷雨',
  '立夏', '小满', '芒种', '夏至', '小暑', '大暑', '立秋', '处暑',
  '白露', '秋分', '寒露', '霜降', '立冬', '小雪', '大雪', '冬至',
];

/// 节气分钟偏移。对应 JS `SOLAR_TERM_INFO`。
const List<int> _solarTermInfo = <int>[
  0, 21208, 42467, 63836, 85337, 107014, 128867, 150921,
  173149, 195551, 218072, 240693, 263343, 285989, 308563, 331033,
  353350, 375494, 397447, 419210, 440795, 462224, 483532, 504758,
];

/// 公历节日。对应 JS `SOLAR_FESTIVALS`。
const Map<String, String> _solarFestivals = <String, String>{
  '01-01': '元旦',
  '02-14': '情人节',
  '03-08': '妇女节',
  '03-12': '植树节',
  '04-01': '愚人节',
  '05-01': '劳动节',
  '05-04': '青年节',
  '06-01': '儿童节',
  '07-01': '建党节',
  '08-01': '建军节',
  '09-10': '教师节',
  '10-01': '国庆节',
  '10-31': '万圣节',
  '12-24': '平安夜',
  '12-25': '圣诞节',
};

/// 农历节日。对应 JS `LUNAR_FESTIVALS`。
const Map<String, String> _lunarFestivals = <String, String>{
  '正月初一': '春节',
  '正月十五': '元宵节',
  '二月初二': '龙抬头',
  '五月初五': '端午节',
  '七月初七': '七夕节',
  '八月十五': '中秋节',
  '九月初九': '重阳节',
  '腊月初八': '腊八节',
  '腊月廿三': '小年',
};

/// ICU 的农历月份名（与 `Intl` 输出一致，注意十二月叫「腊月」）。
const List<String> _lunarMonthNames = <String>[
  '正月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '十一月', '腊月',
];

/// 农历日的中文写法（初一到三十）。对应 JS `chineseLunarDay`。
String chineseLunarDay(int n) {
  const digits = <String>['', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
  if (n <= 10) return '初${digits[n]}';
  if (n < 20) return '十${digits[n - 10]}';
  if (n == 20) return '二十';
  if (n < 30) return '廿${digits[n - 20]}';
  return '三十';
}

int _leapMonthOf(int lunarYear) => lunarInfo[lunarYear - lunarInfoFirstYear] & 0xf;

int _leapDaysOf(int lunarYear) {
  if (_leapMonthOf(lunarYear) == 0) return 0;
  return lunarInfo[lunarYear - lunarInfoFirstYear] & 0x10000 != 0 ? 30 : 29;
}

int _monthDaysOf(int lunarYear, int month) =>
    lunarInfo[lunarYear - lunarInfoFirstYear] & (0x10000 >> month) != 0 ? 30 : 29;

int _lunarYearDays(int lunarYear) {
  var sum = 348;
  for (var i = 0x8000; i > 0x8; i >>= 1) {
    if (lunarInfo[lunarYear - lunarInfoFirstYear] & i != 0) sum += 1;
  }
  return sum + _leapDaysOf(lunarYear);
}

/// 公历日期 → 农历（月份名 + 日）。超出表范围返回 `null`。
({String monthName, int day})? _lunarOf(int year, int month, int day) {
  final offset =
      DateTime.utc(year, month, day).difference(DateTime.utc(1900, 1, 31)).inDays;
  if (offset < 0) return null;
  var remaining = offset;
  var ly = lunarInfoFirstYear;
  while (ly <= lunarInfoLastYear && remaining >= _lunarYearDays(ly)) {
    remaining -= _lunarYearDays(ly);
    ly++;
  }
  if (ly > lunarInfoLastYear) return null;
  final leap = _leapMonthOf(ly);
  for (var m = 1; m <= 12; m++) {
    final len = _monthDaysOf(ly, m);
    if (remaining < len) {
      return (monthName: _lunarMonthNames[m - 1], day: remaining + 1);
    }
    remaining -= len;
    if (leap == m) {
      final leapLen = _leapDaysOf(ly);
      if (remaining < leapLen) {
        return (monthName: '闰${_lunarMonthNames[m - 1]}', day: remaining + 1);
      }
      remaining -= leapLen;
    }
  }
  return null;
}

/// 24 节气名；当天不是节气返回空串。对应 JS `solarTermName`（内部函数）。
String _solarTermName(String isoDay) {
  final d = parseISO(isoDay);
  final year = d.year;
  final month = d.month;
  final day = d.day;
  final base = DateTime.utc(1900, 1, 6, 2, 5).millisecondsSinceEpoch;
  for (var i = (month - 1) * 2; i <= (month - 1) * 2 + 1; i++) {
    final ms = 31556925974.7 * (year - 1900) + _solarTermInfo[i] * 60000 + base;
    final term = DateTime.fromMillisecondsSinceEpoch(ms.truncate(), isUtc: true);
    if (term.month == month && term.day == day) return _solarTermNames[i];
  }
  return '';
}

/// 日历单元格的农历 / 节日 / 节气文字。对应 JS `calendarLabel`。
CalendarLabel calendarLabel(String isoDay) {
  final d = parseISO(isoDay);
  final solarKey = '${pad2(d.month)}-${pad2(d.day)}';
  final solarFestival = _solarFestivals[solarKey] ?? '';
  final lunar = _lunarOf(d.year, d.month, d.day);
  final lunarDayName = lunar == null ? '' : chineseLunarDay(lunar.day);
  final lunarKey = lunar == null ? '' : '${lunar.monthName}$lunarDayName';
  final lunarFest = lunar == null ? '' : (_lunarFestivals[lunarKey] ?? '');
  final term = _solarTermName(isoDay);
  final festival = solarFestival.isNotEmpty ? solarFestival : lunarFest;
  final lunarText = lunar == null ? '' : (lunar.day == 1 ? lunar.monthName : lunarDayName);
  final text = festival.isNotEmpty ? festival : (term.isNotEmpty ? term : lunarText);
  return CalendarLabel(
    text: text,
    festival: festival,
    term: term,
    lunar: lunarText,
    lunarMonth: lunar == null ? '' : lunar.monthName,
    lunarDay: lunar == null ? 0 : lunar.day,
    holiday: festival.isNotEmpty,
  );
}

/// `calendarLabel` 的返回值。
class CalendarLabel {
  const CalendarLabel({
    required this.text,
    required this.festival,
    required this.term,
    required this.lunar,
    required this.lunarMonth,
    required this.lunarDay,
    required this.holiday,
  });

  /// 单元格显示的文字。
  final String text;

  /// 节日名（公历优先）。
  final String festival;

  /// 节气名。
  final String term;

  /// 农历显示文字（初一显示月份名）。
  final String lunar;

  /// 农历月份名。
  final String lunarMonth;

  /// 农历日。
  final int lunarDay;

  /// 是否节日。
  final bool holiday;

  @override
  String toString() => 'CalendarLabel(text: $text, festival: $festival, term: $term, '
      'lunar: $lunar, lunarMonth: $lunarMonth, lunarDay: $lunarDay, holiday: $holiday)';
}
