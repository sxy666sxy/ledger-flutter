/*
 * 生成 lib/src/lunar_table.dart 的农历年编码表（1900–2100）。
 *
 * 参考实现（Web 版 core.js）用 Intl.DateTimeFormat('zh-CN-u-ca-chinese') 取农历，
 * 这里用同一个 ICU 数据源反向生成经典的 17 位「lunarInfo」编码，保证 Dart 侧
 * 与本机 ICU 完全一致。仅在需要重新生成表时手动运行（不属于运行时依赖）：
 *
 *   node tool/generate_lunar_table.mjs
 */
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const fmt = new Intl.DateTimeFormat('zh-CN-u-ca-chinese', {
  month: 'long',
  day: 'numeric',
});

function lunarParts(utcDate) {
  const parts = fmt.formatToParts(utcDate);
  const month = (parts.find((p) => p.type === 'month') || {}).value || '';
  const day = Number((parts.find((p) => p.type === 'day') || {}).value || 0);
  return { month, day };
}

const MONTH_NUM = {
  正月: 1, 二月: 2, 三月: 3, 四月: 4, 五月: 5, 六月: 6,
  七月: 7, 八月: 8, 九月: 9, 十月: 10, 十一月: 11, 冬月: 11, 腊月: 12,
};

function monthInfo(monthName) {
  const leap = monthName.startsWith('闰');
  const base = leap ? monthName.slice(1) : monthName;
  const num = MONTH_NUM[base];
  if (!num) throw new Error('未知农历月份名: ' + monthName);
  return { leap, num };
}

function utcNoon(y, m, d) {
  return new Date(Date.UTC(y, m - 1, d, 12));
}

// 找出公历 y 年的农历正月初一（公历 1/20 – 3/10 之间）
function lunarNewYear(y) {
  for (let m = 1; m <= 3; m++) {
    for (let d = 1; d <= 31; d++) {
      const date = utcNoon(y, m, d);
      if (date.getUTCMonth() + 1 !== m) continue;
      const p = lunarParts(date);
      if (p.month === '正月' && p.day === 1) return date;
    }
  }
  throw new Error('找不到农历新年: ' + y);
}

const MIN_YEAR = 1900;
const MAX_YEAR = 2100;
const table = [];

for (let y = MIN_YEAR; y <= MAX_YEAR; y++) {
  const start = lunarNewYear(y);
  let cursor = new Date(start);
  let leapMonth = 0;
  let leapDays = 0;
  const monthDays = new Array(13).fill(0); // 1..12（非闰）
  let seen = 0;

  while (seen < 13) {
    const p = lunarParts(cursor);
    const info = monthInfo(p.month);
    if (p.day !== 1) throw new Error('不是初一: ' + cursor.toISOString());
    // 统计这个农历月的天数
    let len = 0;
    while (true) {
      const cur = new Date(cursor);
      cur.setUTCDate(cur.getUTCDate() + len);
      const q = lunarParts(cur);
      if (len > 0 && q.day === 1) break;
      len++;
      if (len > 31) throw new Error('月份长度异常: ' + p.month);
    }
    if (info.leap) {
      leapMonth = info.num;
      leapDays = len;
    } else {
      monthDays[info.num] = len;
    }
    cursor.setUTCDate(cursor.getUTCDate() + len);
    seen++;
    const next = monthInfo(lunarParts(cursor).month);
    if (!next.leap && next.num === 1) break; // 下一年正月初一
  }
  for (let m = 1; m <= 12; m++) {
    if (!monthDays[m]) throw new Error(`缺少月份 ${y}-${m}`);
  }

  let bits = 0;
  for (let m = 1; m <= 12; m++) {
    if (monthDays[m] === 30) bits |= 0x10000 >> m;
  }
  bits |= leapMonth;
  if (leapMonth && leapDays === 30) bits |= 0x10000;
  table.push(bits);
}

// —— 用与 Dart 相同的解码算法回读，逐日与 ICU 对比 ——
function leapMonthOf(y) {
  return table[y - MIN_YEAR] & 0xf;
}
function leapDaysOf(y) {
  if (!leapMonthOf(y)) return 0;
  return table[y - MIN_YEAR] & 0x10000 ? 30 : 29;
}
function monthDaysOf(y, m) {
  return table[y - MIN_YEAR] & (0x10000 >> m) ? 30 : 29;
}
const MONTH_NAMES = ['正月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '腊月'];

function yearDaysOf(y) {
  let days = 348;
  for (let i = 0x8000; i > 0x8; i >>= 1) days += table[y - MIN_YEAR] & i ? 1 : 0;
  return days + leapDaysOf(y);
}

function decode(date) {
  const y = date.getUTCFullYear();
  let offset = (Date.UTC(y, date.getUTCMonth(), date.getUTCDate()) - Date.UTC(1900, 0, 31)) / 86400000;
  let ly = MIN_YEAR;
  while (ly <= MAX_YEAR && offset >= yearDaysOf(ly)) {
    offset -= yearDaysOf(ly);
    ly++;
  }
  const leap = leapMonthOf(ly);
  let month = 1;
  let isLeap = false;
  let day = offset + 1;
  outer: for (let m = 1; m <= 12; m++) {
    const len = monthDaysOf(ly, m);
    if (offset < len) {
      month = m;
      isLeap = false;
      day = offset + 1;
      break;
    }
    offset -= len;
    if (leap === m) {
      const leapLen = leapDaysOf(ly);
      if (offset < leapLen) {
        month = m;
        isLeap = true;
        day = offset + 1;
        break outer;
      }
      offset -= leapLen;
    }
  }
  return { month: (isLeap ? '闰' : '') + MONTH_NAMES[month - 1], day };
}

let checked = 0;
const startDate = new Date(Date.UTC(1900, 0, 31, 12));
const endDate = new Date(Date.UTC(MAX_YEAR, 11, 31, 12));
for (let d = new Date(startDate); d <= endDate; d.setUTCDate(d.getUTCDate() + 1)) {
  const expected = lunarParts(d);
  const actual = decode(d);
  if (expected.month !== actual.month || expected.day !== actual.day) {
    throw new Error(
      `回读不一致 ${d.toISOString().slice(0, 10)}: ICU ${expected.month}${expected.day} vs 表 ${actual.month}${actual.day}`,
    );
  }
  checked++;
}

const rows = [];
for (let i = 0; i < table.length; i += 8) {
  rows.push('  ' + table.slice(i, i + 8).map((n) => '0x' + n.toString(16).padStart(5, '0')).join(', ') + ',');
}

const out = `// GENERATED FILE — 不要手改。
// 由 tool/generate_lunar_table.mjs 从 Intl('zh-CN-u-ca-chinese')（ICU 数据）生成，
// 覆盖农历 1900–2100 年。每天已与 ICU 回读比对（${checked} 天）。
//
// 每个元素是农历年的 17 位编码：
//   低 4 位         闰月月份（0 表示无闰月）
//   0x10000 位      闰月为 30 天（否则 29 天）
//   0x8000 >> (m-1) 第 m 个普通月为 30 天（否则 29 天）
// 参考实现：https://github.com/jjonline/calendar.js 所用的同一编码。

const List<int> lunarInfo = <int>[
${rows.join('\n')}
];

int get lunarInfoFirstYear => 1900;
int get lunarInfoLastYear => 2100;
`;

writeFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', 'lib', 'src', 'lunar_table.dart'), out);
console.log(`OK: ${table.length} 年，回读校验 ${checked} 天，已写入 lib/src/lunar_table.dart`);
