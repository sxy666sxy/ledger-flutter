import 'package:flutter_test/flutter_test.dart';
import 'package:xingkong_ledger/main.dart';

void main() {
  testWidgets('首页能渲染 5 个 tab 与月份摘要卡', (tester) async {
    await tester.pumpWidget(const XingkongLedgerApp());
    await tester.pumpAndSettle();

    // 底部导航 5 个标签
    for (final label in ['明细', '日历', '统计', '资产', '我的']) {
      expect(find.text(label), findsWidgets, reason: '缺少导航标签 $label');
    }

    // 明细页的月份摘要卡
    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('还没有设置月预算'), findsOneWidget);
  });
}
