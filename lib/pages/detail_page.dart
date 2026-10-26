import 'package:flutter/material.dart';

import '../theme/star_theme.dart';
import '../widgets/glass_box.dart';

/// 明细页 —— 移植自 Web 版 homeHTML()。
/// 阶段一实现：月份摘要卡 + 按日分组 + 记账入口。
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  // 阶段一的占位数据，接上 ledger_core 后替换为真实账目
  static const _sample = <_Tx>[
    _Tx('宠物', '猫粮', '🐶', '16:28', '猫粮 · 支付宝', 139.46, '今天'),
    _Tx('通讯', '话费充值', '📱', '07:59', '话费充值 · 微信', 51.48, '昨天'),
    _Tx('运动', '羽毛球', '🏀', '18:23', '健身月卡 · 微信', 108.09, '前天'),
    _Tx('餐饮', '晚餐', '🍜', '09:16', '和朋友吃饭 · 支付宝', 55.05, ''),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            children: [
              const _TopBar(),
              const SizedBox(height: 12),
              const _MonthCard(),
              const SizedBox(height: 8),
              ..._sample.map((tx) => _TxTile(tx: tx)),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('记账面板：阶段一接入'))),
              backgroundColor: StarColors.primary,
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassBox(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            children: [
              Text('📒', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                '日常账本',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.arrow_drop_down, color: StarColors.inkSoft),
            ],
          ),
        ),
        const Spacer(),
        const Icon(Icons.search, color: StarColors.inkSoft),
        const SizedBox(width: 18),
        const Icon(Icons.calendar_month_outlined, color: StarColors.inkSoft),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      decoration: BoxDecoration(
        gradient: StarColors.cardGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20254D).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '本月支出',
                style: TextStyle(fontSize: 14, color: StarColors.cardTitle),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left, size: 18, color: Colors.white70),
                    Text(
                      '2026年10月',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Colors.white70),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '¥3,281',
            style: TextStyle(
              fontSize: 42,
              height: 1.05,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              _Metric(label: '本月收入', value: '+¥12,086.00'),
              SizedBox(width: 26),
              _Metric(label: '本月结余', value: '¥8,804.81'),
              SizedBox(width: 26),
              _Metric(label: '记账', value: '21 笔'),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                '还没有设置月预算',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              Spacer(),
              Text(
                '设置预算 ›',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: StarColors.cardTitle),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Tx {
  const _Tx(
    this.category,
    this.title,
    this.emoji,
    this.time,
    this.sub,
    this.amount,
    this.dayLabel,
  );
  final String category;
  final String title;
  final String emoji;
  final String time;
  final String sub;
  final double amount;
  final String dayLabel;
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final _Tx tx;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 18, 6, 10),
          child: Row(
            children: [
              Text(
                tx.dayLabel.isEmpty ? '23' : tx.dayLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '10月 · 周一',
                style: TextStyle(fontSize: 13, color: StarColors.inkSoft),
              ),
              const Spacer(),
              Text(
                '支出 ¥${tx.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: StarColors.inkSoft),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B6CFF).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E9EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(tx.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.category} · ${tx.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.time} · ${tx.sub}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: StarColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '-¥${tx.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: StarColors.expense,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
