# 星空记账 · Flutter 版

Web 版（[`sxy666sxy/ledger`](https://github.com/sxy666sxy/ledger) v2.1.15，WebView 封装）的 Flutter 重写。
**两个版本并行存在**，Flutter 版成熟前不影响现有用户。

## 为什么不能在手机上直接编译

Flutter 官方 Linux 宿主机 SDK **只发布 x86_64**（`releases_linux.json` 里 746 个版本，含 arm64 的归档为 0）。
`gen_snapshot` / `frontend_server` 等工具链二进制是 x64 ELF，无法在 aarch64 手机上本地执行。
所以：**代码在本机（Android/Termux）写和测，APK 交给 GitHub Actions 构建**（`.github/workflows/flutter.yml`，2~4 分钟出包）。

纯 Dart 的数据层不受此限制 —— 本机 `dart 3.13.7` 可直接跑单元测试，所以数据层是 TDD 开发的。

## 目录

```
ledger-flutter/
├── lib/
│   ├── main.dart                # 5 tab 外壳 + 玻璃导航
│   ├── theme/star_theme.dart    # 视觉基线（星空浅色），后续扩 12 套主题
│   ├── widgets/glass_box.dart   # 液态玻璃（BackdropFilter）
│   └── pages/
│       ├── detail_page.dart     # 明细页（已出视觉骨架）
│       └── stub_pages.dart      # 日历/统计/资产/我的（占位 + 移植清单）
├── packages/ledger_core/        # 纯 Dart 数据层，1:1 移植 assets/core.js
└── .github/workflows/flutter.yml
```

`android/` 等平台目录不入库，由 CI 的 `flutter create --platforms=android` 生成，避免样板代码污染仓库。

## 阶段计划

| 阶段 | 内容 | 交付物 |
| --- | --- | --- |
| P0 | 工程骨架 + CI + 数据层移植（core.js → Dart，带单测） | 可安装的骨架 APK |
| P1 | 明细 + 记账面板（键盘/分类/账户/日期/备注/标签）+ 本地存储 + **JSON 备份导入导出** | 可日用 MVP |
| P2 | 统计（月/年/自定义、柱状、环形、排行、净资产曲线）+ 日历页（农历/节气/热力） | 功能对齐 |
| P3 | 资产/账户、预算、周期记账、多账本、搜索、多选导出 | 功能齐全 |
| P4 | 12 套主题、液态玻璃打磨、锁屏、附件、Excel 导入导出 | 视觉/细节对齐 |

## 数据迁移（硬要求）

老用户账目存在 WebView 的 `localStorage['xingkong.ledger.v4']`，Flutter 版读不到。
因此 **P1 必须能导入现有 JSON 备份**，且 schema 保持 v4 不变：

1. 老 App：我的 → 数据与备份 → 导出 JSON
2. 新 App：我的 → 数据与备份 → 导入 JSON
3. 确认账目一致后再卸载老 App

包名用 `com.xingkong.ledger.flutter` 与 WebView 版（`com.xingkong.ledger`）区分，**迁移期可并存**。
注意：若两个 App 用同一个签名密钥且包名相同会互相覆盖安装，Flutter 版刻意避开了这一点。

## 构建

推送到 `main` 即触发 CI，产物在 Actions 的 `Artifacts` 里（`xingkong-ledger-flutter-apk`）。

当前 CI 用 debug key 签名（可直接安装验证）；等阶段验收通过，再接入仓库已有的
`ANDROID_KEYSTORE_BASE64` 等 secrets 做 release 签名。
