/// JS 语义兼容层。
///
/// Web 版 `core.js` 大量依赖 JS 的隐式类型转换（`Number(x) || 0`、`String(x)`、
/// `Math.round` 的「.5 向 +∞ 取整」、稳定排序等）。Dart 的默认行为与之不同，
/// 因此这里集中实现这些语义，业务代码一律通过这些函数取值，保证移植忠实。
library;

/// 与 JS `Math.round` 等价：`floor(x + 0.5)`。
///
/// 注意 Dart 的 `double.round()` 是「.5 远离 0」，例如 `(-0.5).round() == -1`，
/// 而 JS 是 `Math.round(-0.5) == -0`。金额按分取整必须用这个函数。
int jsRound(num value) {
  final x = value.toDouble();
  if (x.isNaN) {
    throw ArgumentError.value(value, 'value', 'Math.round(NaN) 在 Dart 侧无整数表示');
  }
  if (x.isInfinite) {
    throw ArgumentError.value(value, 'value', 'Math.round(Infinity) 在 Dart 侧无整数表示');
  }
  return (x + 0.5).floor();
}

/// 与 JS `Math.ceil` 等价（对整数/浮点一致）。
int jsCeil(num value) => value.ceil();

/// 与 JS `Number(value)` 等价（只覆盖 JSON 可能出现的类型）。
///
/// 无法解析时返回 `double.nan`，与 JS 一致。
double jsToNumber(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is bool) return value ? 1 : 0;
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return 0;
    if (text == 'Infinity' || text == '+Infinity') return double.infinity;
    if (text == '-Infinity') return -double.infinity;
    if (text == 'NaN') return double.nan;
    if (text.length > 2 && text.startsWith('0x') || text.length > 2 && text.startsWith('0X')) {
      final hex = int.tryParse(text.substring(2), radix: 16);
      if (hex != null) return hex.toDouble();
    }
    var literal = text;
    // JS 接受 "1." 这种写法，Dart 的 tryParse 不接受。
    if (literal.endsWith('.')) literal = '${literal}0';
    final parsed = double.tryParse(literal);
    return parsed ?? double.nan;
  }
  return double.nan;
}

/// 与 JS `Number(value) || 0` 等价（NaN / -0 → 0）。
double jsNumberOrZero(Object? value) {
  final n = jsToNumber(value);
  return n.isNaN ? 0 : n;
}

/// 与 JS 的 truthiness 等价（用于 `!!x`、`if (x)`）。
bool jsTruthy(Object? value) {
  if (value == null || value == false) return false;
  if (value is num) return value != 0 && !value.isNaN;
  if (value is String) return value.isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

/// 与 JS `String(value)` 等价（模板字符串 / 比较时的隐式转换）。
String jsString(Object? value) {
  if (value == null) return 'null';
  if (value is String) return value;
  if (value is bool) return value ? 'true' : 'false';
  if (value is int) return value.toString();
  if (value is double) return _jsNumberToString(value);
  if (value is num) return value.toString();
  if (value is List) return value.map((e) => jsString(e)).join(',');
  return value.toString();
}

/// 与 JS 的数字转字符串规则（`String(1.0) === '1'`）对齐。
String _jsNumberToString(double value) {
  if (value.isNaN) return 'NaN';
  if (value == double.infinity) return 'Infinity';
  if (value == double.negativeInfinity) return '-Infinity';
  if (value == value.truncateToDouble() && value.abs() < 1e21) {
    return value.toInt().toString();
  }
  return value.toString();
}

/// JS 侧的数字写入 JSON 时不会保留 `.0`；Dart 的 `jsonEncode(1.0)` 会输出 `1.0`。
/// 在 `toJson` 里统一过一遍，保证与 localStorage v4 备份一致。
num jsonNum(num value) {
  if (value is double &&
      value.isFinite &&
      value == value.truncateToDouble() &&
      value.abs() < 9007199254740992.0) {
    return value.toInt();
  }
  return value;
}

/// 稳定排序（JS 的 `Array.prototype.sort` 自 ES2019 起保证稳定）。
///
/// Dart 的 `List.sort` 不保证稳定，凡是 JS 结果依赖原始顺序的排序都用这个函数。
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final list = items.toList();
  final indexed = List<({int index, T value})>.generate(
    list.length,
    (i) => (index: i, value: list[i]),
  );
  indexed.sort((a, b) {
    final result = compare(a.value, b.value);
    return result != 0 ? result : a.index.compareTo(b.index);
  });
  return indexed.map((e) => e.value).toList();
}

/// 深拷贝 JSON 兼容结构（对应 JS 的 `JSON.parse(JSON.stringify(x))`）。
Object? jsonDeepCopy(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries) jsString(entry.key): jsonDeepCopy(entry.value),
    };
  }
  if (value is List) return value.map(jsonDeepCopy).toList();
  return value;
}
