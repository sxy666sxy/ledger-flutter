import 'package:flutter/material.dart';

import '../theme/star_theme.dart';

/// 阶段二/三 的移植目标页：先占位，保留真实页面骨架（标题 + 说明 + 待办清单），
/// 让每个阶段的版本都能装上看、能对照 Web 版验收。
class PortStubPage extends StatelessWidget {
  const PortStubPage({
    super.key,
    required this.title,
    required this.icon,
    required this.sourceFn,
    required this.items,
  });

  final String title;
  final IconData icon;

  /// 对应的 Web 版渲染函数，便于逐页对照
  final String sourceFn;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Web 版对应：$sourceFn()',
            style: const TextStyle(fontSize: 12, color: StarColors.inkSoft),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: StarColors.primary.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: StarColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      '待移植清单',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 10),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: StarColors.inkSoft,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            it,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: StarColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) => const PortStubPage(
    title: '日历',
    icon: Icons.calendar_month_outlined,
    sourceFn: 'calendarHTML / calendarPageHTML',
    items: [
      '月历网格 + 每日收支、热力背景（支出红 / 收入绿）',
      '农历、节气、节日标注（core.js 里已有完整表，Dart 侧随数据层一起搬）',
      '点击日期展开当日账单，可加当天账单',
      '月份左右滑动切换、右上角设置开关热力/农历',
    ],
  );
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) => const PortStubPage(
    title: '统计',
    icon: Icons.pie_chart_outline,
    sourceFn: 'statsHTML / statsExpenseDataHTML / charts.js',
    items: [
      '四个入口：日常 / 月统计 / 年统计 / 自定义区间',
      '按日柱状图（支出 / 收入 / 结余可切换）+ 每日净资产曲线',
      '分类环形占比、分类排行、收支桑基对比',
      '年度热力图、月度报表、月份总结',
    ],
  );
}

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) => const PortStubPage(
    title: '资产',
    icon: Icons.account_balance_wallet_outlined,
    sourceFn: 'assetsHTML / openBalanceEditor / deleteAccountWithBills',
    items: [
      '资产账户 / 信用卡负债 / 净资产汇总',
      '点击余额改当前余额（自动反推初始余额）',
      '长按账户删除（有关联账单/周期规则时一并处理）',
      '记账账户开关、账户间转账',
    ],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const PortStubPage(
    title: '我的',
    icon: Icons.person_outline,
    sourceFn: 'profileHTML / openData / openCategories / openTheme',
    items: [
      '数据与备份：导出 JSON / Excel / CSV，导入 JSON / Excel / CSV',
      '分类管理：改名、换图标颜色、移动、删除（带账单转移）',
      '外观主题 12 套 + 自定义背景图',
      '预算、周期记账、多账本、密码锁、关于',
    ],
  );
}
