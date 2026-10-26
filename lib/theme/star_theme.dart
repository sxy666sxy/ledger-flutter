import 'package:flutter/material.dart';

/// 星空记账的视觉基线。
/// 颜色取自 Web 版 assets/app.css 的「星空浅色」主题，后续 12 套主题
/// 会扩展为 ThemeExtension + 独立背景资源，这里先固化浅色基线。
class StarColors {
  static const primary = Color(0xFF5B6CFF);
  static const bgTop = Color(0xFFEDEFFA);
  static const bgBottom = Color(0xFFF8F9FE);
  static const cardTitle = Color(0xFF9AA3C7);
  static const ink = Color(0xFF1F2340);
  static const inkSoft = Color(0xFF6B7392);
  static const expense = Color(0xFFE5484D);
  static const income = Color(0xFF12A150);
  static const navBg = Color(0xCCFFFFFF);

  /// 首页顶部「本月支出」卡片的靛蓝渐变
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF20254D), Color(0xFF151A33)],
  );
}

class StarTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: StarColors.primary,
      brightness: Brightness.light,
    ).copyWith(surface: StarColors.bgBottom, primary: StarColors.primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: null,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: StarColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: StarColors.ink),
      ),
    );
  }

  /// 页面背景：淡紫渐变 + 一点点星光
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [StarColors.bgTop, StarColors.bgBottom],
    stops: [0.0, 0.55],
  );
}
