/// 金额工具。所有加减都以「分」为单位，避免 `0.1 + 0.2` 的浮点误差。
library;

import 'js_compat.dart';

/// 金额转分。对应 JS `toCents`。
///
/// 与 JS 一致使用 `Math.round`（.5 向 +∞），不是 Dart 的 `.round()`。
int toCents(num? n) => jsRound((n ?? 0) * 100);

/// 分转金额。整数金额返回 `int`，否则返回 `double`（保持 JSON 备份里没有 `.0`）。
num fromCents(int c) => jsonNum(c / 100);

/// 四舍五入到 2 位小数。对应 JS `round2`。
num round2(num? n) {
  final value = n ?? 0;
  if (value is double && (value.isNaN || value.isInfinite)) return value;
  return fromCents(jsRound(value * 100));
}

/// 千分位金额格式化。对应 JS `money(n, digits)`。
///
/// `digits` 省略时为 2；`digits: 0` 不输出小数点。
String money(num? n, [int? digits]) {
  final d = digits ?? 2;
  final value = n ?? 0;
  final v = (value is double && value.isNaN) ? 0 : value;
  final fixed = v.abs().toStringAsFixed(d);
  final parts = fixed.split('.');
  final integer = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
  final decimal = parts.length > 1 ? parts[1] : '';
  return '${v < 0 ? '-' : ''}$integer${d > 0 ? '.$decimal' : ''}';
}

/// 金额拆分。对应 JS `amountParts`（返回 `{ sign, int, dec }`）。
AmountParts amountParts(num? n) {
  final value = n ?? 0;
  final abs = round2(value).abs();
  final fixed = abs.toStringAsFixed(2);
  final parts = fixed.split('.');
  return AmountParts(
    sign: value < 0 ? '-' : '',
    int: parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ','),
    dec: parts.length > 1 ? parts[1] : '',
  );
}

/// `amountParts` 的返回值。
class AmountParts {
  const AmountParts({required this.sign, required this.int, required this.dec});

  /// 负号（负数时是 `-`，否则空串）。
  final String sign;

  /// 千分位整数部分。
  final String int;

  /// 两位小数部分。
  final String dec;

  @override
  bool operator ==(Object other) =>
      other is AmountParts && other.sign == sign && other.int == int && other.dec == dec;

  @override
  int get hashCode => Object.hash(sign, int, dec);

  @override
  String toString() => 'AmountParts(sign: $sign, int: $int, dec: $dec)';
}

/// 解析 `12+3.5-1` 这类算式；失败返回 `double.nan`。对应 JS `parseAmountExpr`。
///
/// 每一项先转成「分」再累加，所以 `0.1+0.2` 得到精确的 `0.3`。
double parseAmountExpr(Object? expr) {
  if (expr is num) {
    if (expr is double && !expr.isFinite) return double.nan;
    return round2(expr).toDouble();
  }
  final s = jsString(expr ?? '').replaceAll(RegExp(r'[\s,，]'), '');
  if (s.isEmpty) return double.nan;
  final valid = RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)([+-](\d+(\.\d*)?|\.\d+))*$');
  if (!valid.hasMatch(s)) return double.nan;
  final tokens = RegExp(r'[+-]?(\d+(?:\.\d*)?|\.\d+)').allMatches(s).map((m) => m[0]!).toList();
  var cents = 0;
  for (final token in tokens) {
    if (token == '+' || token == '-') continue;
    final v = double.tryParse(token);
    if (v == null || !v.isFinite) return double.nan;
    cents += jsRound(v * 100);
  }
  return fromCents(cents).toDouble();
}

/// 不带千分位的两位小数字符串。对应 JS `plainMoney`（导入导出用）。
String plainMoney(Object? n) {
  final value = round2(jsNumberOrZero(n));
  return value.toStringAsFixed(2);
}

/// 导入时解析金额/数值。对应 JS `parseImportNumber`。
double parseImportNumber(Object? value) {
  if (value is num) {
    final d = value.toDouble();
    return d.isFinite ? d : 0;
  }
  final text = jsString(value ?? '').replaceAll(RegExp(r'[¥￥$€£\s,，]'), '');
  if (text.isEmpty) return 0;
  final n = jsToNumber(text);
  return n.isFinite ? n : 0;
}
