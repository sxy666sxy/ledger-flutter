import 'package:flutter/material.dart';

import 'pages/detail_page.dart';
import 'pages/stub_pages.dart';
import 'theme/star_theme.dart';

void main() => runApp(const XingkongLedgerApp());

class XingkongLedgerApp extends StatelessWidget {
  const XingkongLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '星空记账',
      debugShowCheckedModeBanner: false,
      theme: StarTheme.light(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DetailPage(),
    CalendarPage(),
    StatsPage(),
    AssetsPage(),
    ProfilePage(),
  ];

  static const _navItems = <(IconData, String)>[
    (Icons.format_list_bulleted, '明细'),
    (Icons.calendar_month_outlined, '日历'),
    (Icons.pie_chart_outline, '统计'),
    (Icons.account_balance_wallet_outlined, '资产'),
    (Icons.person_outline, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: StarTheme.pageGradient),
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: StarColors.navBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: StarColors.primary.withValues(alpha: 0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _navItems.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _index = i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _navItems[i].$1,
                              size: 24,
                              color: i == _index
                                  ? StarColors.primary
                                  : StarColors.inkSoft.withValues(alpha: 0.75),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _navItems[i].$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == _index
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: i == _index
                                    ? StarColors.primary
                                    : StarColors.inkSoft.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
