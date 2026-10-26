/// 数据模型。
///
/// JSON 结构与 Web 版 localStorage v4 完全一致（字段名、null 语义、嵌套结构）。
/// 与 JS 的普通对象相比，Dart 侧多了 `unknown`：用来原样保留本层不认识的键
/// （例如 `settings.customThemeImage`），保证导出/导入不丢字段。
/// 注意：`migrateData` 的行为与 JS 一致——账单/分类/账户/周期规则会被重建，
/// 其 `unknown` 会被清空；账本、预算、设置、顶层则保留未知键。
library;

import 'js_compat.dart';

/// 附件。
class Attachment {
  Attachment({this.name, this.dataUrl, this.type = ''});

  /// 文件名（JS 侧要求 `typeof name === 'string'`，否则导入时被丢弃）。
  String? name;

  /// dataURL（可为 null）。
  String? dataUrl;

  /// MIME 类型。
  String type;

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        name: json['name'] is String ? json['name'] as String : null,
        dataUrl: json['dataUrl'] == null ? null : jsString(json['dataUrl']),
        type: json['type'] is String ? json['type'] as String : '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'dataUrl': dataUrl,
        'type': type,
      };
}

/// 账本预算。
class Budget {
  Budget({this.total = 0, Map<String, num>? categories, Map<String, dynamic>? unknown})
      : categories = categories ?? <String, num>{},
        unknown = unknown ?? <String, dynamic>{};

  /// 总预算。
  num total;

  /// 分类预算：分类 id → 金额。
  final Map<String, num> categories;

  /// 未识别的键（原样保留）。
  final Map<String, dynamic> unknown;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        total: _finiteOrZero(json['total']),
        categories: _numMap(json['categories']),
        unknown: _unknownKeys(json, _budgetKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'total': jsonNum(total),
        'categories': <String, dynamic>{
          for (final entry in categories.entries) entry.key: jsonNum(entry.value),
        },
        ...unknown,
      };
}

/// 账本。
class Book {
  Book({
    this.id = '',
    this.name = '',
    this.icon,
    this.color,
    Budget? budget,
    this.createdAt,
    Map<String, dynamic>? unknown,
  })  : budget = budget ?? Budget(),
        unknown = unknown ?? <String, dynamic>{};

  /// 账本 id。
  String id;

  /// 名称。
  String name;

  /// 图标。
  String? icon;

  /// 颜色。
  String? color;

  /// 预算。
  Budget budget;

  /// 创建时间（ISO）。
  String? createdAt;

  /// 未识别的键。
  final Map<String, dynamic> unknown;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: _string(json['id']),
        name: _string(json['name']),
        icon: _stringOrNull(json['icon']),
        color: _stringOrNull(json['color']),
        budget: json['budget'] is Map
            ? Budget.fromJson(normalizeJsonMap(json['budget'] as Map))
            : Budget(),
        createdAt: _stringOrNull(json['createdAt']),
        unknown: _unknownKeys(json, _bookKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'budget': budget.toJson(),
        if (createdAt != null) 'createdAt': createdAt,
        ...unknown,
      };
}

/// 分类。
class Category {
  Category({
    this.id = '',
    this.name = '',
    this.icon,
    this.color,
    this.type = '',
    this.order,
    this.builtin,
    Map<String, dynamic>? unknown,
  }) : unknown = unknown ?? <String, dynamic>{};

  /// 分类 id。
  String id;

  /// 名称。
  String name;

  /// 图标。
  String? icon;

  /// 颜色。
  String? color;

  /// `expense` / `income`（迁移后保证合法）。
  String type;

  /// 排序。
  num? order;

  /// 是否内置。
  bool? builtin;

  /// 未识别的键（迁移后清空，与 JS 重建对象一致）。
  final Map<String, dynamic> unknown;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: _string(json['id']),
        name: _string(json['name']),
        icon: _stringOrNull(json['icon']),
        color: _stringOrNull(json['color']),
        type: _string(json['type']),
        order: _finiteOrNull(json['order']),
        builtin: json['builtin'] == null ? null : jsTruthy(json['builtin']),
        unknown: _unknownKeys(json, _categoryKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'type': type,
        if (order != null) 'order': jsonNum(order!),
        if (builtin != null) 'builtin': builtin,
        ...unknown,
      };
}

/// 账户。
class Account {
  Account({
    this.id = '',
    this.name = '',
    this.type = '',
    this.icon,
    this.color,
    this.initial = 0,
    this.include,
    this.bookkeeping,
    this.order,
    Map<String, dynamic>? unknown,
  }) : unknown = unknown ?? <String, dynamic>{};

  /// 账户 id。
  String id;

  /// 名称。
  String name;

  /// 类型（`cash` / `alipay` / …，迁移后保证是已知值）。
  String type;

  /// 图标。
  String? icon;

  /// 颜色。
  String? color;

  /// 初始余额。
  num initial;

  /// 是否计入总资产（迁移后为 bool）。
  bool? include;

  /// 是否参与记账（迁移后为 bool）。
  bool? bookkeeping;

  /// 排序（迁移后为数字）。
  num? order;

  /// 未识别的键（迁移后清空）。
  final Map<String, dynamic> unknown;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: _string(json['id']),
        name: _string(json['name']),
        type: _string(json['type']),
        icon: _stringOrNull(json['icon']),
        color: _stringOrNull(json['color']),
        initial: _finiteOrZero(json['initial']),
        include: json['include'] == null ? null : jsTruthy(json['include']),
        bookkeeping: json['bookkeeping'] == null ? null : jsTruthy(json['bookkeeping']),
        order: _finiteOrNull(json['order']),
        unknown: _unknownKeys(json, _accountKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'initial': jsonNum(initial),
        if (include != null) 'include': include,
        if (bookkeeping != null) 'bookkeeping': bookkeeping,
        if (order != null) 'order': jsonNum(order!),
        ...unknown,
      };
}

/// 账单。
class Transaction {
  Transaction({
    this.id,
    this.bookId,
    this.type = '',
    this.amount = 0,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.date = '',
    this.time = '',
    this.subcategory = '',
    this.refund = 0,
    this.discount = 0,
    this.reimburseAccount = '',
    this.reimburseAmount = 0,
    this.reimburseNote = '',
    this.currency = '',
    this.foreignAmount = 0,
    this.location = '',
    this.creator = '',
    this.extra = '',
    List<Attachment>? attachments,
    this.note = '',
    List<String>? tags,
    this.recurringId,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? unknown,
  })  : attachments = attachments ?? <Attachment>[],
        tags = tags ?? <String>[],
        unknown = unknown ?? <String, dynamic>{};

  /// 账单 id。
  String? id;

  /// 所属账本 id。
  String? bookId;

  /// `expense` / `income` / `transfer`（迁移后保证合法）。
  String type;

  /// 金额（永远为正数）。
  num amount;

  /// 分类 id（转账为 null）。
  String? categoryId;

  /// 支出/收入账户 id。
  String? accountId;

  /// 转入账户 id（仅转账）。
  String? toAccountId;

  /// `YYYY-MM-DD`。
  String date;

  /// `HH:MM`。
  String time;

  /// 二级分类。
  String subcategory;

  /// 退款。
  num refund;

  /// 优惠。
  num discount;

  /// 报销账户名。
  String reimburseAccount;

  /// 报销金额。
  num reimburseAmount;

  /// 报销明细。
  String reimburseNote;

  /// 多币种代码。
  String currency;

  /// 外币金额。
  num foreignAmount;

  /// 地址。
  String location;

  /// 创建用户。
  String creator;

  /// 其他。
  String extra;

  /// 附件（最多 5 个）。
  List<Attachment> attachments;

  /// 备注。
  String note;

  /// 标签。
  List<String> tags;

  /// 来源周期规则 id。
  String? recurringId;

  /// 创建时间（ISO）。
  String? createdAt;

  /// 更新时间（ISO 或 null）。
  String? updatedAt;

  /// 未识别的键（迁移后清空）。
  final Map<String, dynamic> unknown;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: _stringOrNull(json['id']),
        bookId: _stringOrNull(json['bookId']),
        type: _string(json['type']),
        amount: _finiteOrZero(json['amount']),
        categoryId: _stringOrNull(json['categoryId']),
        accountId: _stringOrNull(json['accountId']),
        toAccountId: _stringOrNull(json['toAccountId']),
        date: _string(json['date']),
        time: _string(json['time']),
        subcategory: _string(json['subcategory']),
        refund: _finiteOrZero(json['refund']),
        discount: _finiteOrZero(json['discount']),
        reimburseAccount: _string(json['reimburseAccount']),
        reimburseAmount: _finiteOrZero(json['reimburseAmount']),
        reimburseNote: _string(json['reimburseNote']),
        currency: _string(json['currency']),
        foreignAmount: _finiteOrZero(json['foreignAmount']),
        location: _string(json['location']),
        creator: _string(json['creator']),
        extra: _string(json['extra']),
        attachments: json['attachments'] is List
            ? (json['attachments'] as List)
                .whereType<Map>()
                .map((e) => Attachment.fromJson(normalizeJsonMap(e)))
                .where((a) => a.name != null)
                .toList()
            : <Attachment>[],
        note: _string(json['note']),
        tags: json['tags'] is List
            ? (json['tags'] as List).whereType<String>().toList()
            : <String>[],
        recurringId: _stringOrNull(json['recurringId']),
        createdAt: _stringOrNull(json['createdAt']),
        updatedAt: _stringOrNull(json['updatedAt']),
        unknown: _unknownKeys(json, _transactionKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'bookId': bookId,
        'type': type,
        'amount': jsonNum(amount),
        'categoryId': categoryId,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'date': date,
        'time': time,
        'subcategory': subcategory,
        'refund': jsonNum(refund),
        'discount': jsonNum(discount),
        'reimburseAccount': reimburseAccount,
        'reimburseAmount': jsonNum(reimburseAmount),
        'reimburseNote': reimburseNote,
        'currency': currency,
        'foreignAmount': jsonNum(foreignAmount),
        'location': location,
        'creator': creator,
        'extra': extra,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'note': note,
        'tags': tags,
        'recurringId': recurringId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        ...unknown,
      };
}

/// 周期记账规则。
class Recurring {
  Recurring({
    this.id = '',
    this.bookId,
    this.type,
    this.amount = 0,
    this.categoryId,
    this.accountId,
    this.note = '',
    this.freq = 'monthly',
    this.startDate,
    this.lastRun,
    this.enabled,
    Map<String, dynamic>? unknown,
  }) : unknown = unknown ?? <String, dynamic>{};

  /// 规则 id。
  String id;

  /// 账本 id。
  String? bookId;

  /// `expense` / `income`（迁移后保证合法）。
  String? type;

  /// 金额。
  num amount;

  /// 分类 id。
  String? categoryId;

  /// 账户 id。
  String? accountId;

  /// 备注。
  String note;

  /// `daily` / `weekly` / `monthly` / `yearly`。
  String freq;

  /// 起始日期。
  String? startDate;

  /// 上次已生成日期。
  String? lastRun;

  /// 是否启用（`null` 视作未显式关闭；`applyRecurring` 会跳过）。
  bool? enabled;

  /// 未识别的键（迁移后清空）。
  final Map<String, dynamic> unknown;

  factory Recurring.fromJson(Map<String, dynamic> json) => Recurring(
        id: _string(json['id']),
        bookId: _stringOrNull(json['bookId']),
        type: _stringOrNull(json['type']),
        amount: _finiteOrZero(json['amount']),
        categoryId: _stringOrNull(json['categoryId']),
        accountId: _stringOrNull(json['accountId']),
        note: _string(json['note']),
        freq: _string(json['freq']),
        startDate: _stringOrNull(json['startDate']),
        lastRun: _stringOrNull(json['lastRun']),
        enabled: json['enabled'] == null ? null : jsTruthy(json['enabled']),
        unknown: _unknownKeys(json, _recurringKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'bookId': bookId,
        'type': type,
        'amount': jsonNum(amount),
        'categoryId': categoryId,
        'accountId': accountId,
        'note': note,
        'freq': freq,
        'startDate': startDate,
        'lastRun': lastRun,
        'enabled': enabled,
        ...unknown,
      };
}

/// 设置。
class Settings {
  Settings({
    this.theme = '',
    this.pinHash,
    this.lockEnabled = false,
    this.currency = '',
    this.demo = false,
    this.onboarded = false,
    this.calendarHeat = true,
    this.calendarLunar = true,
    Map<String, dynamic>? unknown,
  }) : unknown = unknown ?? <String, dynamic>{};

  /// `auto` / `light` / `dark`（迁移后保证合法）。
  String theme;

  /// 隐私锁 PIN 的哈希。
  String? pinHash;

  /// 是否启用隐私锁（迁移时由 pinHash 推导）。
  bool lockEnabled;

  /// 货币符号。
  String currency;

  /// 是否为演示数据。
  bool demo;

  /// 是否已完成引导。
  bool onboarded;

  /// 日历热力图。
  bool calendarHeat;

  /// 日历显示农历。
  bool calendarLunar;

  /// 未识别的键（如 `customThemeImage`，原样保留）。
  final Map<String, dynamic> unknown;

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        theme: _string(json['theme']),
        pinHash: _stringOrNull(json['pinHash']),
        lockEnabled: jsTruthy(json['lockEnabled']),
        currency: _string(json['currency']),
        demo: jsTruthy(json['demo']),
        onboarded: jsTruthy(json['onboarded']),
        calendarHeat: json['calendarHeat'] != false,
        calendarLunar: json['calendarLunar'] != false,
        unknown: _unknownKeys(json, _settingsKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'theme': theme,
        'pinHash': pinHash,
        'lockEnabled': lockEnabled,
        'currency': currency,
        'demo': demo,
        'onboarded': onboarded,
        'calendarHeat': calendarHeat,
        'calendarLunar': calendarLunar,
        ...unknown,
      };
}

/// 整个账本数据树。
class LedgerData {
  LedgerData({
    this.version = 0,
    this.createdAt,
    Settings? settings,
    List<Book>? books,
    this.activeBookId = '',
    List<Category>? categories,
    List<Account>? accounts,
    List<Transaction>? transactions,
    List<String>? tags,
    List<Recurring>? recurring,
    Map<String, dynamic>? unknown,
  })  : settings = settings ?? Settings(),
        books = books ?? <Book>[],
        categories = categories ?? <Category>[],
        accounts = accounts ?? <Account>[],
        transactions = transactions ?? <Transaction>[],
        tags = tags ?? <String>[],
        recurring = recurring ?? <Recurring>[],
        unknown = unknown ?? <String, dynamic>{};

  /// 数据版本。
  num version;

  /// 创建时间（ISO，可选）。
  String? createdAt;

  /// 设置。
  Settings settings;

  /// 账本列表。
  List<Book> books;

  /// 当前账本 id。
  String activeBookId;

  /// 分类列表。
  List<Category> categories;

  /// 账户列表。
  List<Account> accounts;

  /// 账单列表。
  List<Transaction> transactions;

  /// 标签列表。
  List<String> tags;

  /// 周期规则列表。
  List<Recurring> recurring;

  /// 未识别的顶层键。
  final Map<String, dynamic> unknown;

  factory LedgerData.fromJson(Map<String, dynamic> json) => LedgerData(
        version: _finiteOrZero(json['version']),
        createdAt: _stringOrNull(json['createdAt']),
        settings: json['settings'] is Map
            ? Settings.fromJson(normalizeJsonMap(json['settings'] as Map))
            : Settings(),
        books: json['books'] is List
            ? (json['books'] as List)
                .whereType<Map>()
                .map((e) => Book.fromJson(normalizeJsonMap(e)))
                .toList()
            : <Book>[],
        activeBookId: _string(json['activeBookId']),
        categories: json['categories'] is List
            ? (json['categories'] as List)
                .whereType<Map>()
                .map((e) => Category.fromJson(normalizeJsonMap(e)))
                .toList()
            : <Category>[],
        accounts: json['accounts'] is List
            ? (json['accounts'] as List)
                .whereType<Map>()
                .map((e) => Account.fromJson(normalizeJsonMap(e)))
                .toList()
            : <Account>[],
        transactions: json['transactions'] is List
            ? (json['transactions'] as List)
                .whereType<Map>()
                .map((e) => Transaction.fromJson(normalizeJsonMap(e)))
                .toList()
            : <Transaction>[],
        tags: json['tags'] is List
            ? (json['tags'] as List).whereType<String>().toList()
            : <String>[],
        recurring: json['recurring'] is List
            ? (json['recurring'] as List)
                .whereType<Map>()
                .map((e) => Recurring.fromJson(normalizeJsonMap(e)))
                .toList()
            : <Recurring>[],
        unknown: _unknownKeys(json, _dataKeys),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': jsonNum(version),
        if (createdAt != null) 'createdAt': createdAt,
        'settings': settings.toJson(),
        'books': books.map((b) => b.toJson()).toList(),
        'activeBookId': activeBookId,
        'categories': categories.map((c) => c.toJson()).toList(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'tags': tags,
        'recurring': recurring.map((r) => r.toJson()).toList(),
        ...unknown,
      };
}

// —— JSON 读取辅助 ——

/// 把任意 `Map` 规范为 `Map<String, dynamic>`（键统一转字符串）。
Map<String, dynamic> normalizeJsonMap(Map<dynamic, dynamic> json) => <String, dynamic>{
      for (final entry in json.entries) jsString(entry.key): entry.value,
    };

String _string(Object? value) => value == null ? '' : jsString(value);

String? _stringOrNull(Object? value) => value == null ? null : jsString(value);

num _finiteOrZero(Object? value) {
  final n = jsToNumber(value);
  return n.isFinite ? jsonNum(n) : 0;
}

num? _finiteOrNull(Object? value) {
  if (value == null) return null;
  final n = jsToNumber(value);
  return n.isFinite ? jsonNum(n) : null;
}

Map<String, num> _numMap(Object? value) {
  if (value is! Map) return <String, num>{};
  return <String, num>{
    for (final entry in value.entries) jsString(entry.key): _finiteOrZero(entry.value),
  };
}

Map<String, dynamic> _unknownKeys(Map<String, dynamic> json, Set<String> known) =>
    <String, dynamic>{
      for (final entry in json.entries)
        if (!known.contains(entry.key)) entry.key: entry.value,
    };

const Set<String> _dataKeys = <String>{
  'version', 'createdAt', 'settings', 'books', 'activeBookId',
  'categories', 'accounts', 'transactions', 'tags', 'recurring',
};

const Set<String> _settingsKeys = <String>{
  'theme', 'pinHash', 'lockEnabled', 'currency', 'demo', 'onboarded',
  'calendarHeat', 'calendarLunar',
};

const Set<String> _bookKeys = <String>{
  'id', 'name', 'icon', 'color', 'budget', 'createdAt',
};

const Set<String> _budgetKeys = <String>{'total', 'categories'};

const Set<String> _categoryKeys = <String>{
  'id', 'name', 'icon', 'color', 'type', 'order', 'builtin',
};

const Set<String> _accountKeys = <String>{
  'id', 'name', 'type', 'icon', 'color', 'initial', 'include',
  'bookkeeping', 'order',
};

const Set<String> _transactionKeys = <String>{
  'id', 'bookId', 'type', 'amount', 'categoryId', 'accountId', 'toAccountId',
  'date', 'time', 'subcategory', 'refund', 'discount', 'reimburseAccount',
  'reimburseAmount', 'reimburseNote', 'currency', 'foreignAmount', 'location',
  'creator', 'extra', 'attachments', 'note', 'tags', 'recurringId',
  'createdAt', 'updatedAt',
};

const Set<String> _recurringKeys = <String>{
  'id', 'bookId', 'type', 'amount', 'categoryId', 'accountId', 'note',
  'freq', 'startDate', 'lastRun', 'enabled',
};
