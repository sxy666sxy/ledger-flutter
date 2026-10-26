/// 数据初始化、演示数据、迁移/校验、导入导出载荷、查询辅助。
library;

import 'dart:math' as math;

import 'constants.dart';
import 'dates.dart';
import 'js_compat.dart';
import 'models.dart';
import 'money.dart';

int _seq = 0;
final math.Random _random = math.Random();

/// 生成 id。对应 JS `uid`。
String uid(String? prefix) {
  _seq = (_seq + 1) % 1296;
  final nowPart = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final seqPart = _seq.toRadixString(36);
  const alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  final randomPart = <String>[
    for (var i = 0; i < 4; i++) alphabet[_random.nextInt(alphabet.length)],
  ].join();
  return '${prefix ?? 'id'}_$nowPart$seqPart$randomPart';
}

/// 默认分类。对应 JS `makeCategories`。
List<Category> makeCategories() {
  final out = <Category>[];
  for (var i = 0; i < expenseCategoryDefs.length; i++) {
    final c = expenseCategoryDefs[i];
    out.add(Category(
      id: 'c_${c[0]}',
      name: c[1],
      icon: c[2],
      color: c[3],
      type: 'expense',
      order: i,
      builtin: true,
    ));
  }
  for (var i = 0; i < incomeCategoryDefs.length; i++) {
    final c = incomeCategoryDefs[i];
    out.add(Category(
      id: 'c_${c[0]}',
      name: c[1],
      icon: c[2],
      color: c[3],
      type: 'income',
      order: i,
      builtin: true,
    ));
  }
  return out;
}

/// 默认账户（每次返回新对象）。对应 JS `DEFAULT_ACCOUNTS`。
List<Account> defaultAccounts() => <Account>[
      Account(id: 'a_cash', name: '现金', type: 'cash', icon: '💵', color: '#22c55e', initial: 800, include: true),
      Account(id: 'a_alipay', name: '支付宝', type: 'alipay', icon: '💠', color: '#0ea5e9', initial: 6800, include: true),
      Account(id: 'a_wechat', name: '微信', type: 'wechat', icon: '🟢', color: '#10b981', initial: 3200, include: true),
      Account(id: 'a_bank', name: '银行卡', type: 'bank', icon: '🏦', color: '#6366f1', initial: 10000, include: true),
      Account(id: 'a_credit', name: '信用卡', type: 'credit', icon: '💳', color: '#f43f5e', initial: 0, include: true),
    ];

/// 默认数据。对应 JS `createDefaultData(options)`。
LedgerData createDefaultData({bool demo = false}) {
  final now = nowISO();
  const bookId = 'b_main';
  final data = LedgerData(
    version: version,
    createdAt: now,
    settings: Settings(
      theme: 'auto',
      pinHash: null,
      lockEnabled: false,
      currency: '¥',
      demo: demo,
      onboarded: false,
      calendarHeat: true,
      calendarLunar: true,
    ),
    books: <Book>[
      Book(
        id: bookId,
        name: '日常账本',
        icon: '📒',
        color: '#0e9f6e',
        budget: Budget(total: 0),
        createdAt: now,
      ),
    ],
    activeBookId: bookId,
    categories: makeCategories(),
    accounts: defaultAccounts(),
    transactions: <Transaction>[],
    tags: <String>[],
    recurring: <Recurring>[],
  );
  if (demo) seedDemoData(data);
  return data;
}

/// 生成演示账单。对应 JS `seedDemoData`，返回新建笔数。
int seedDemoData(LedgerData data) {
  final bookId = data.books.first.id;
  final now = DateTime.now();
  final templates = <({
    String type,
    String category,
    List<String> notes,
    num min,
    num max,
    String account,
  })>[
    (type: 'expense', category: 'c_food', notes: <String>['午饭', '咖啡', '外卖', '和朋友吃饭', '早餐'], min: 15, max: 58, account: 'a_alipay'),
    (type: 'expense', category: 'c_transport', notes: <String>['地铁', '打车', '公交'], min: 3, max: 42, account: 'a_wechat'),
    (type: 'expense', category: 'c_shopping', notes: <String>['生活用品', '超市采购', '网购'], min: 35, max: 260, account: 'a_alipay'),
    (type: 'expense', category: 'c_daily', notes: <String>['纸巾牙膏', '洗衣液', '水果'], min: 12, max: 75, account: 'a_alipay'),
    (type: 'expense', category: 'c_fun', notes: <String>['电影票', '游戏充值', '演出'], min: 25, max: 180, account: 'a_wechat'),
    (type: 'expense', category: 'c_study', notes: <String>['买书', '网课'], min: 30, max: 199, account: 'a_alipay'),
    (type: 'expense', category: 'c_phone', notes: <String>['话费充值'], min: 50, max: 100, account: 'a_wechat'),
    (type: 'expense', category: 'c_clothes', notes: <String>['T恤', '鞋子'], min: 99, max: 399, account: 'a_alipay'),
    (type: 'expense', category: 'c_sport', notes: <String>['羽毛球', '健身月卡'], min: 30, max: 199, account: 'a_wechat'),
    (type: 'expense', category: 'c_medical', notes: <String>['药品'], min: 18, max: 120, account: 'a_cash'),
    (type: 'expense', category: 'c_pet', notes: <String>['猫粮'], min: 68, max: 188, account: 'a_alipay'),
    (type: 'income', category: 'c_invest', notes: <String>['基金分红'], min: 20, max: 160, account: 'a_bank'),
  ];
  num rand(num a, num b) => a + _random.nextDouble() * (b - a);
  T pick<T>(List<T> arr) => arr[_random.nextInt(arr.length)];
  final subMap = <String, List<String>>{
    'c_food': <String>['早餐', '午餐', '晚餐', '咖啡', '外卖'],
    'c_transport': <String>['地铁', '公交', '打车'],
    'c_shopping': <String>['超市', '网购'],
    'c_daily': <String>['日用', '水果'],
    'c_fun': <String>['电影', '游戏', '演出'],
    'c_study': <String>['书籍', '网课'],
    'c_clothes': <String>['上衣', '鞋子'],
    'c_sport': <String>['羽毛球', '健身'],
    'c_pet': <String>['猫粮'],
    'c_medical': <String>['药品'],
  };

  var created = 0;
  for (var back = 2; back >= 0; back--) {
    final y = now.year;
    final m0 = now.month - 1 - back;
    final first = DateTime(y, m0 + 1, 1, 12);
    final yy = first.year;
    final mm = first.month - 1;
    final dim = daysInMonth(yy, mm + 1);
    final today = now.day;
    final maxDay = back == 0 ? today : dim;
    final key = '$yy-${pad2(mm + 1)}';

    final fixed = <({
      int day,
      String type,
      String cat,
      String note,
      num amount,
      String account,
      List<String> tags,
    })>[
      (day: 5, type: 'expense', cat: 'c_home', note: '房租', amount: 1800, account: 'a_bank', tags: <String>['固定支出']),
      (day: 6, type: 'expense', cat: 'c_utility', note: '水电费', amount: 128, account: 'a_alipay', tags: <String>[]),
      (day: 8, type: 'expense', cat: 'c_home', note: '宽带续费', amount: 90, account: 'a_wechat', tags: <String>[]),
      (day: 10, type: 'income', cat: 'c_salary', note: '工资', amount: 12000, account: 'a_bank', tags: <String>['工资']),
      (day: 18, type: 'income', cat: 'c_invest', note: '理财收益', amount: 86, account: 'a_bank', tags: <String>[]),
    ];
    for (var idx = 0; idx < fixed.length; idx++) {
      final f = fixed[idx];
      if (f.day > maxDay) continue;
      data.transactions.add(Transaction(
        id: uid('t'),
        bookId: bookId,
        type: f.type,
        amount: f.amount,
        categoryId: f.cat,
        accountId: f.account,
        toAccountId: null,
        date: '$key-${pad2(f.day)}',
        time: '${pad2(7 + idx)}:${pick(<String>['12', '35', '48'])}',
        note: f.note,
        tags: List<String>.of(f.tags),
        subcategory: subMap[f.cat] != null ? pick(subMap[f.cat]!) : '',
        refund: 0,
        discount: 0,
        reimburseAccount: '',
        reimburseAmount: 0,
        reimburseNote: '',
        currency: '',
        foreignAmount: 0,
        location: '',
        creator: '我',
        extra: '',
        attachments: <Attachment>[],
        createdAt: toISOString(DateTime(yy, mm + 1, f.day, 9)),
        updatedAt: null,
      ));
      created++;
    }

    for (var d = 1; d <= maxDay; d++) {
      if (d == 5 || d == 10 || d == 18) continue;
      final rolls = _random.nextDouble() < 0.25 ? 2 : (_random.nextDouble() < 0.75 ? 1 : 0);
      for (var r = 0; r < rolls; r++) {
        final tpl = pick(templates);
        final amount = round2(rand(tpl.min, tpl.max));
        if (back == 0 && _random.nextDouble() < 0.25) continue;
        data.transactions.add(Transaction(
          id: uid('t'),
          bookId: bookId,
          type: tpl.type,
          amount: amount,
          categoryId: tpl.category,
          accountId: tpl.account,
          toAccountId: null,
          date: '$key-${pad2(d)}',
          time: '${pad2(6 + (_random.nextDouble() * 15).floor())}:${pad2((_random.nextDouble() * 60).floor())}',
          note: pick(tpl.notes),
          tags: _random.nextDouble() < 0.18 ? <String>['日常'] : <String>[],
          subcategory: subMap[tpl.category] != null ? pick(subMap[tpl.category]!) : '',
          refund: 0,
          discount: 0,
          reimburseAccount: '',
          reimburseAmount: 0,
          reimburseNote: '',
          currency: '',
          foreignAmount: 0,
          location: _random.nextDouble() < 0.08 ? '公司' : '',
          creator: '我',
          extra: '',
          attachments: <Attachment>[],
          createdAt: toISOString(DateTime(yy, mm + 1, d, 10)),
          updatedAt: null,
        ));
        created++;
      }
    }
  }
  data.transactions.sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'));
  data.tags = <String>['固定支出', '日常', '工资'];
  data.settings.demo = true;
  _adjustDemoBalances(data);
  return created;
}

/// 让演示数据的账户余额保持自然。对应 JS `adjustDemoBalances`（内部函数）。
void _adjustDemoBalances(LedgerData data) {
  final flow = <String, double>{for (final a in data.accounts) a.id: 0};
  for (final t in data.transactions) {
    final id = t.accountId;
    final to = t.toAccountId;
    if (t.type == 'income' && id != null && flow[id] != null) flow[id] = flow[id]! + t.amount;
    if (t.type == 'expense' && id != null && flow[id] != null) flow[id] = flow[id]! - t.amount;
    if (t.type == 'transfer') {
      if (id != null && flow[id] != null) flow[id] = flow[id]! - t.amount;
      if (to != null && flow[to] != null) flow[to] = flow[to]! + t.amount;
    }
  }
  const targets = <String, num>{
    'cash': 800,
    'alipay': 3200,
    'wechat': 2200,
    'bank': 22000,
    'credit': 0,
    'invest': 5000,
    'other': 500,
  };
  for (final a in data.accounts) {
    final target = targets[a.type] ?? 500;
    final needed = round2(target - (flow[a.id] ?? 0));
    if (needed > a.initial) a.initial = jsonNum(jsCeil(needed / 100) * 100);
  }
}

/// 迁移/归一化数据。对应 JS `migrateData`。
///
/// 与 JS 的差异：Dart 侧不修改入参，返回一个新的 [LedgerData]；传入非对象返回 `null`。
LedgerData? migrateData(Object? input) {
  final LedgerData data;
  if (input is LedgerData) {
    data = LedgerData.fromJson(normalizeJsonMap(input.toJson()));
  } else if (input is Map) {
    data = LedgerData.fromJson(normalizeJsonMap(input));
  } else {
    return null;
  }
  data.version = version;

  if (data.books.isEmpty) {
    data.books = <Book>[_defaultBook()];
  }
  for (final b in data.books) {
    b.id = b.id.isNotEmpty ? b.id : uid('b');
    b.name = b.name.isNotEmpty ? b.name : '未命名账本';
    b.icon = (b.icon != null && b.icon!.isNotEmpty) ? b.icon : '📒';
    b.color = (b.color != null && b.color!.isNotEmpty) ? b.color : '#0e9f6e';
    b.budget.total = jsNumberOrZero(b.budget.total);
  }
  if (!data.books.any((b) => b.id == data.activeBookId)) {
    data.activeBookId = data.books.first.id;
  }

  if (data.categories.isEmpty) data.categories = makeCategories();
  data.categories = <Category>[
    for (var i = 0; i < data.categories.length; i++)
      if (data.categories[i].id.isNotEmpty && data.categories[i].name.isNotEmpty)
        Category(
          id: data.categories[i].id,
          name: data.categories[i].name,
          icon: (data.categories[i].icon != null && data.categories[i].icon!.isNotEmpty)
              ? data.categories[i].icon
              : '🏷️',
          color: (data.categories[i].color != null && data.categories[i].color!.isNotEmpty)
              ? data.categories[i].color
              : '#94a3b8',
          type: data.categories[i].type == 'income' ? 'income' : 'expense',
          order: data.categories[i].order ?? i,
          builtin: data.categories[i].builtin == true,
        ),
  ];

  if (data.accounts.isEmpty) data.accounts = defaultAccounts();
  data.accounts = <Account>[
    for (var i = 0; i < data.accounts.length; i++)
      if (data.accounts[i].id.isNotEmpty && data.accounts[i].name.isNotEmpty)
        _normalizeAccount(data.accounts[i], i),
  ];

  final now = nowISO();
  data.transactions = <Transaction>[
    for (final t in data.transactions)
      if (t.date.isNotEmpty) _normalizeTransaction(t, data.activeBookId, now),
  ];

  data.recurring = <Recurring>[
    for (final r in data.recurring)
      if (r.id.isNotEmpty) _normalizeRecurring(r, data.activeBookId),
  ];

  final s = data.settings;
  s.theme = const <String>['auto', 'light', 'dark'].contains(s.theme) ? s.theme : 'auto';
  s.currency = s.currency.isNotEmpty ? s.currency : '¥';
  s.pinHash = (s.pinHash != null && s.pinHash!.isNotEmpty) ? s.pinHash : null;
  s.lockEnabled = s.pinHash != null;
  s.demo = s.demo;
  s.onboarded = s.onboarded;
  s.calendarHeat = s.calendarHeat;
  s.calendarLunar = s.calendarLunar;

  final rawTags = List<String>.of(data.tags);
  data.tags = <String>[];
  final seenTags = <String>{};
  for (final tag in rawTags) {
    if (seenTags.add(tag)) data.tags.add(tag);
  }
  return data;
}

Book _defaultBook() => Book(
      id: 'b_main',
      name: '日常账本',
      icon: '📒',
      color: '#0e9f6e',
      budget: Budget(total: 0),
      createdAt: nowISO(),
    );

Account _normalizeAccount(Account a, int index) {
  final validType = accountTypes.containsKey(a.type) ? a.type : 'other';
  final iconSpec = accountTypes[a.type] ?? accountTypes['other']!;
  return Account(
    id: a.id,
    name: a.name,
    type: validType,
    icon: (a.icon != null && a.icon!.isNotEmpty) ? a.icon : iconSpec.icon,
    color: (a.color != null && a.color!.isNotEmpty) ? a.color : '#94a3b8',
    initial: round2(a.initial),
    include: a.include != false,
    bookkeeping: a.bookkeeping != false,
    order: a.order ?? index,
  );
}

Transaction _normalizeTransaction(Transaction t, String activeBookId, String now) {
  final type = (t.type == 'income' || t.type == 'transfer') ? t.type : 'expense';
  String? nonEmpty(String? value) => (value != null && value.isNotEmpty) ? value : null;
  String slice(String value, int end) => value.length > end ? value.substring(0, end) : value;
  final time = RegExp(r'^\d{2}:\d{2}').hasMatch(t.time) ? t.time.substring(0, 5) : '12:00';
  return Transaction(
    id: nonEmpty(t.id) ?? uid('t'),
    bookId: nonEmpty(t.bookId) ?? activeBookId,
    type: type,
    amount: round2(t.amount.abs()),
    categoryId: type == 'transfer' ? null : nonEmpty(t.categoryId),
    accountId: nonEmpty(t.accountId),
    toAccountId: type == 'transfer' ? nonEmpty(t.toAccountId) : null,
    date: slice(t.date, 10),
    time: time,
    subcategory: slice(t.subcategory, 20),
    refund: math.max(0, round2(t.refund)),
    discount: math.max(0, round2(t.discount)),
    reimburseAccount: slice(t.reimburseAccount, 40),
    reimburseAmount: math.max(0, round2(t.reimburseAmount)),
    reimburseNote: slice(t.reimburseNote, 200),
    currency: slice(t.currency, 12),
    foreignAmount: math.max(0, round2(t.foreignAmount)),
    location: slice(t.location, 120),
    creator: slice(t.creator, 20),
    extra: slice(t.extra, 200),
    attachments: t.attachments.take(5).map((a) => Attachment(
          name: slice(a.name ?? '', 120),
          dataUrl: a.dataUrl,
          type: slice(a.type, 40),
        )).toList(),
    note: t.note,
    tags: List<String>.of(t.tags),
    recurringId: nonEmpty(t.recurringId),
    createdAt: nonEmpty(t.createdAt) ?? now,
    updatedAt: nonEmpty(t.updatedAt),
  );
}

Recurring _normalizeRecurring(Recurring r, String activeBookId) {
  String? nonEmpty(String? value) => (value != null && value.isNotEmpty) ? value : null;
  const freqs = <String>['daily', 'weekly', 'monthly', 'yearly'];
  return Recurring(
    id: r.id,
    bookId: nonEmpty(r.bookId) ?? activeBookId,
    type: r.type == 'income' ? 'income' : 'expense',
    amount: round2(r.amount),
    categoryId: nonEmpty(r.categoryId),
    accountId: nonEmpty(r.accountId),
    note: r.note,
    freq: freqs.contains(r.freq) ? r.freq : 'monthly',
    startDate: nonEmpty(r.startDate) ?? todayISO(),
    lastRun: nonEmpty(r.lastRun),
    enabled: r.enabled != false,
  );
}

/// 备份校验结果。对应 JS `validateBackup` 的 `{ ok, data }` / `{ ok, error }`。
class ValidateBackupResult {
  const ValidateBackupResult.ok(LedgerData this.data)
      : ok = true,
        error = null;

  const ValidateBackupResult.fail(String this.error)
      : ok = false,
        data = null;

  /// 是否校验通过。
  final bool ok;

  /// 迁移后的数据（失败时为 `null`）。
  final LedgerData? data;

  /// 失败原因。
  final String? error;
}

/// 校验备份文件。对应 JS `validateBackup`。
ValidateBackupResult validateBackup(Object? obj) {
  if (obj == null) {
    return const ValidateBackupResult.fail('文件内容不是有效的数据');
  }
  LedgerData? migrated;
  if (obj is LedgerData) {
    migrated = migrateData(obj);
  } else if (obj is! Map) {
    if (obj is List) {
      return const ValidateBackupResult.fail('缺少账本或账单数据，无法导入');
    }
    return const ValidateBackupResult.fail('文件内容不是有效的数据');
  } else {
    final map = normalizeJsonMap(obj);
    final rawData = map['data'];
    final dataMap = rawData is Map ? normalizeJsonMap(rawData) : map;
    if (dataMap['books'] is! List || dataMap['transactions'] is! List) {
      return const ValidateBackupResult.fail('缺少账本或账单数据，无法导入');
    }
    migrated = migrateData(dataMap);
  }
  if (migrated == null) {
    return const ValidateBackupResult.fail('数据格式无法识别');
  }
  return ValidateBackupResult.ok(migrated);
}

/// 导出载荷。对应 JS `exportPayload` 的返回值。
class ExportPayload {
  ExportPayload({
    required this.app,
    required this.version,
    required this.exportedAt,
    required this.data,
  });

  /// 应用名。
  final String app;

  /// 版本号。
  final num version;

  /// 导出时间（ISO）。
  final String exportedAt;

  /// 数据副本。
  final LedgerData data;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'app': app,
        'version': version,
        'exportedAt': exportedAt,
        'data': data.toJson(),
      };
}

/// 生成备份载荷。对应 JS `exportPayload`。
ExportPayload exportPayload(LedgerData data) => ExportPayload(
      app: '星空记账 · 本地版',
      version: version,
      exportedAt: nowISO(),
      data: LedgerData.fromJson(normalizeJsonMap(data.toJson())),
    );

/// 分类 id → 分类。对应 JS `categoryMap`。
Map<String, Category> categoryMap(LedgerData data) =>
    <String, Category>{for (final c in data.categories) c.id: c};

/// 账户 id → 账户。对应 JS `accountMap`。
Map<String, Account> accountMap(LedgerData data) =>
    <String, Account>{for (final a in data.accounts) a.id: a};

/// 当前账本，找不到时回退第一个。对应 JS `activeBook`。
Book? activeBook(LedgerData data) {
  for (final b in data.books) {
    if (b.id == data.activeBookId) return b;
  }
  return data.books.isEmpty ? null : data.books.first;
}

/// 某类型的分类，按 order 排序。对应 JS `categoriesOf`。
List<Category> categoriesOf(LedgerData data, String type) => stableSorted(
      data.categories.where((c) => c.type == type),
      (a, b) => ((a.order ?? 0) - (b.order ?? 0)).toInt(),
    );
