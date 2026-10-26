/// 常量表。与 Web 版 `core.js` 中的大写常量一一对应（Dart 侧改 lowerCamelCase）。
library;

/// 数据版本号。对应 JS `VERSION`。
const int version = 2;

/// 收支类型中文。对应 JS `TYPE_CN`。
const Map<String, String> typeCN = <String, String>{
  'expense': '支出',
  'income': '收入',
  'transfer': '转账',
};

/// 与「星空记账」账单导出列保持一致。对应 JS `BILL_HEADERS`。
const List<String> billHeaders = <String>[
  '日期',
  '收支类型',
  '金额',
  '类别',
  '二级分类',
  '账户',
  '账本',
  '退款',
  '优惠',
  '备注',
  '标签',
  '报销账户',
  '报销金额',
  '报销明细',
  '多币种',
  '地址',
  '创建用户',
  '其他',
  '附件1',
  '附件2',
  '附件3',
  '附件4',
  '附件5',
];

/// 数值型导出列。对应 JS `BILL_NUMERIC`。
const List<String> billNumeric = <String>['金额', '退款', '优惠', '报销金额'];

/// 周期频率中文。对应 JS `FREQ_CN`。
const Map<String, String> freqCN = <String, String>{
  'daily': '每天',
  'weekly': '每周',
  'monthly': '每月',
  'yearly': '每年',
};

/// 账户类型定义。对应 JS `ACCOUNT_TYPES`。
const Map<String, AccountType> accountTypes = <String, AccountType>{
  'cash': AccountType(name: '现金', icon: '💵', liability: false),
  'alipay': AccountType(name: '支付宝', icon: '💠', liability: false),
  'wechat': AccountType(name: '微信', icon: '🟢', liability: false),
  'bank': AccountType(name: '银行卡', icon: '🏦', liability: false),
  'invest': AccountType(name: '投资', icon: '📈', liability: false),
  'credit': AccountType(name: '信用卡', icon: '💳', liability: true),
  'other': AccountType(name: '其它', icon: '👛', liability: false),
};

/// 账户类型元信息。
class AccountType {
  const AccountType({required this.name, required this.icon, required this.liability});

  /// 中文名。
  final String name;

  /// 图标。
  final String icon;

  /// 是否为负债类账户（信用卡）。
  final bool liability;
}

/// 内置标签。对应 JS `BUILTIN_TAGS`。
const List<String> builtinTags = <String>[
  '餐饮',
  '交通',
  '购物',
  '居住',
  '娱乐',
  '医疗',
  '学习',
  '通讯',
  '人情',
  '旅行',
  '宠物',
  '运动',
  '工资',
  '理财',
  '兼职',
  '红包',
  '报销',
  '固定支出',
  '日常',
];

/// 默认支出分类定义：[key, 名称, 图标, 颜色]。
const List<List<String>> expenseCategoryDefs = <List<String>>[
  <String>['food', '餐饮', '🍜', '#f97316'],
  <String>['transport', '交通', '🚌', '#3b82f6'],
  <String>['shopping', '购物', '🛍️', '#ec4899'],
  <String>['fun', '娱乐', '🎮', '#8b5cf6'],
  <String>['home', '居住', '🏠', '#0ea5e9'],
  <String>['medical', '医疗', '💊', '#ef4444'],
  <String>['study', '学习', '📚', '#6366f1'],
  <String>['phone', '通讯', '📱', '#14b8a6'],
  <String>['clothes', '服饰', '👕', '#d946ef'],
  <String>['daily', '日用', '🧻', '#84cc16'],
  <String>['travel', '旅行', '✈️', '#06b6d4'],
  <String>['sport', '运动', '🏀', '#f59e0b'],
  <String>['pet', '宠物', '🐶', '#f43f5e'],
  <String>['beauty', '美容', '💄', '#e879f9'],
  <String>['digital', '数码', '💻', '#64748b'],
  <String>['utility', '水电', '💡', '#eab308'],
  <String>['baby', '育儿', '🧸', '#fb923c'],
  <String>['social', '人情', '🎁', '#db2777'],
  <String>['other', '其它', '📦', '#94a3b8'],
];

/// 默认收入分类定义：[key, 名称, 图标, 颜色]。
const List<List<String>> incomeCategoryDefs = <List<String>>[
  <String>['salary', '工资', '💼', '#10b981'],
  <String>['bonus', '奖金', '🏆', '#f59e0b'],
  <String>['invest', '理财', '📈', '#0ea5e9'],
  <String>['parttime', '兼职', '🧑‍💻', '#6366f1'],
  <String>['redpacket', '红包', '🧧', '#ef4444'],
  <String>['reimburse', '报销', '🧾', '#14b8a6'],
  <String>['refund', '退款', '↩️', '#8b5cf6'],
  <String>['other_income', '其它', '💰', '#94a3b8'],
];
