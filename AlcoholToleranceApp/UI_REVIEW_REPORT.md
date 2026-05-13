# 🎨 UI/UX 走查报告 — 2026-05-13

## 🚨 P0 — 阻塞级

### 1. 双重代码库分裂（路径隔离）
- **根目录**: `AlcoholToleranceApp/` — 我设计的 6 View 规范
- **agents/developer/**: 另一套 Views（Home/Test/Knowledge + BACGauge）
- 只有 HistoryView 和 ProfileView 名字重合，实现还不同
- AppTheme 两套独立实现：
  - 根: `NeonColors` struct + `NeonCardModifier`
  - dev: `AppTheme` enum（嵌套 Color/Font enum）+ 可选 `init?(hex:)`
- **后果**: 后续开发必然滚雪球，bug 必须两边修

**解决方案**: 根目录 `AlcoholToleranceApp/` 为唯一 truth source，dev 版合并后删除。

### 2. 主题系统分裂
| 项目 | 根目录 | developer |
|------|--------|-----------|
| 背景色 | `NeonColors.background = #0A0A0F` | `AppTheme.Color.darkBgStart = #0D0D1A` |
| 强调色 | `NeonColors.accent = #06B6D4` (电光蓝) | `AppTheme.Color.electricBlue = #06B6D4` |
| 霓虹紫 | 无（仅 `BACLevel` 颜色映射有） | `AppTheme.Color.neonPurple = #8B5CF6` |
| 卡片背景 | `NeonColors.cardBackground = #1A1A2E` | `AppTheme.Color.surface = white.opacity(0.06)` |
| 辉光效果 | `NeonColors.glow = #06B6D4.opacity(0.4)` | 无 |
| 卡片修饰器 | `neonCard()` 统一修饰符 | 无（inline style） |
| 字体系统 | 无自定义字体 | `AppTheme.Font`（PingFang SC + SF Mono） |
| Hex 初始化 | `init(hex:)` 非可选 | `init?(hex:)` 可选（可能 nil） |

### 3. View 命名 / 映射不一致
| 我的 6 VM 合同 | 根 Views | developer Views |
|---------------|----------|----------------|
| DashboardVM | DashboardView ✅ | HomeView ❌ |
| DrinkLoggerVM | DrinkLoggerView ✅ | 无（内嵌在 HomeView?） |
| SoberTestVM | SoberTestView ✅ | TestView ❌ |
| HistoryVM | HistoryView ✅ | HistoryView ✅（实现不同） |
| ProfileVM | ProfileView ✅ | ProfileView ✅（实现不同） |
| SettingsVM | SettingsView ✅ | KnowledgeView ❌ |

---

## 🟡 P1 — 建议修

### 4. BAC 颜色映射两套
- 根: `BACLevel.color` → `Color(hex: BACLevel.colorHex)` 8 级独立色
- dev: `AppTheme.bacLevelColor()` switch 映射（8 级，色值不同）
- **色值有微妙差异**（例如 sober: 根 #10B981 vs dev #10B981 一致，但 euphoric: 根 `？` vs dev #8B5CF6）

### 5. 无关键动效
- 所有 View 缺少页面过渡动画（默认无衔接）
- 按钮点击无反馈（haptic、scale effect）
- BAC gauge 弧形渐变没有加载动画

### 6. 缺乏统一的 Loading / Empty / Error 状态组件
- HistoryView 有自己的 empty state
- Dashboard 无 loading skeleton
- 各 View 状态处理不统一

---

## 🔵 P2 — 细节优化

### 7. 刷新按钮无 loading 态
- Dashboard 刷新按钮一直可点，没有 disabled + ProgressView 状态

### 8. Profile 编辑入口不一致
- 根: sheet + 独立 ProfileEditView
- dev: 全屏 NavigationStack + Form
- 应该统一为一种（根版 sheet 方案更 SwiftUI-native）

### 9. 无全局错误处理
- View 中没有 `.alert(error:)` 或 `.task` 错误捕获
- 网络/数据库失败时用户无反馈

---

## ✅ 做得好的（保留）
- ✅ 根版 `neonCard()` 修饰器设计优雅，组件间复用好
- ✅ 根版 270° BAC 弧形仪表盘交互设计完整
- ✅ dev 版字体系统（PingFang SC + SF Mono）值得合入
- ✅ dev 版 `AppTheme` 枚举嵌套 Color 结构清晰
- ✅ BACGauge 组件化设计好，应该保留

---

## 📋 合并路线建议

1. **统一代码库**: 删 `agents/developer/AlcoholToleranceApp/`，只保留根目录
2. **合入 dev 的亮点**:
   - AppTheme 字体系统 → 合入 NeonColors
   - BACGauge 组件 → 替换根版内联 gauge
   - KnowledgeView 功能 → 需确认是否要加为第 7 个 View
3. **统一颜色**: 以 `NeonColors` 为准，补充缺少的 purple、pink
4. **统一 `init(hex:)`**: 统一用非可选版本，用 `#` prefix 风格
5. **增补动效**: 页面过渡 + 按钮反馈
6. **统一状态组件**: LoadingView、EmptyStateView、ErrorView
