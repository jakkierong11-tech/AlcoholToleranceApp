# 酒量测试 App — Bug 清单

> 来源：测试工程师 (@tester) + 审查工程师 (@reviewer) + 架构设计师 (@designer)
> 生成日期：2026-05-11
> 最后更新：2026-05-14 22:47

---

## P0 🔴 必须修

### BUG-001: `UserManager.fetchOrCreateUser()` 不存在 ✅ 已修复
- **位置**: `ProfileVM.swift:15`
- **原因**: 接口契约画了饼但 UserManager 没实现
- **影响**: ProfileVM 编译失败
- **修复**: 2026-05-11 22:00, 总管补实现 `UserManager.fetchOrCreateUser()` — 查当前用户，不存在则创建默认用户
- **审查确认**: ✅ 确认已修复（2026-05-14）

### BUG-002: `UserManager.updateUser()` 不存在 ✅ 已修复
- **位置**: `ProfileVM.swift:20,25,30,35`
- **原因**: ProfileVM 调用了不存在的方法名
- **影响**: ProfileVM 多处编译失败
- **修复**: 已全部改用 `updateProfile(user:isMale:)` / `updateProfile(user:weightKg:)` / `updateProfile(user:nickname:)`
- **审查确认**: ✅ 确认已修复（2026-05-14）

---

## P1 🟡 尽快修

### BUG-003: BACLevel 颜色映射重复 ✅ 已修复
- **位置**: BACLevel.colorHex（已含 8 色）+ AppTheme.swift（2026-05-12 新建）
- **原因**: ~~AppTheme 只定义了 4 个颜色变量~~
- **修复**: BACLevel 枚举已定义 8 个独立 colorHex，AppTheme.swift 提供 `BACLevel.color` 映射
- **审查确认**: ✅ 确认已修复（2026-05-14）

---

## P2 🟢 待排期

### BUG-004: @StateObject → @Observable 迁移
- **位置**: 全部 ViewModel（ProfileVM / TestSessionVM / HistoryVM）
- **原因**: 当前使用 iOS 14+ 的 `@StateObject` / `ObservableObject`，iOS 17+ 推荐 `@Observable` Macro
- **影响**: iOS 17+ 上行为可能不一致，无法利用 Observation 框架的细粒度更新
- **建议**: 等核心功能稳定 + BACGauge 落地后再迁移，风险更低

### BUG-005: 法律阈值缺少 EU/US 标准 ✅ 已修复
- **位置**: `BACCalculator.swift` — `drivingAdvice()` / `isOverLegalLimit()`
- **原因**: 当前仅覆盖中国标准（0.02% 酒驾 / 0.08% 醉驾），未提供 EU（0.05%）/ US（0.08%）等地区选项
- **修复**: 2026-05-12 总管新增 `LegalRegion` 枚举（.cn/.us/.eu），`drivingAdvice(bac:region:)` 和 `isOverLegalLimit(bac:region:threshold:)` 支持按地区判断
- **审查确认**: ✅ 确认已修复（2026-05-14）

---

## 已解决

### RES-001: BACLevel 枚举命名一致性问题
- **发现于**: 2026-05-10，审查工程师（审查报告中 P0#1）
- **修复于**: 2026-05-11（审查后、测试验证前，由开发工程师修复）
- **结果**: ✅ AppTheme.swift 已统一使用业务名 `.sober/.mild/...`，无 `.zero/.slight` 二义性命名
- **审查确认**: @reviewer ✅ 确认已修复

### FIX-001: `calculateSessionScore` BAC 评分逻辑反转
- **修于**: 2026-05-11，架构设计师
- **改动**: `min(bacPercent/0.4*50, 50)` → `max(50 - (bacPercent/0.4*50), 0)`
- **效果**: BAC 越低分越高，符合酒量耐受语义
- **审查确认**: @reviewer ✅ 确认已修复

### FIX-002: `calculateToleranceScore` 经验分封顶错误
- **修于**: 2026-05-11，架构设计师
- **改动**: e 上限 20 → 100（`e * 0.2` 现在能给满 20 分）
- **效果**: 50 次会话经验分满值，不再被错误 cap 到 4 分
- **审查确认**: @reviewer ✅ 确认已修复

### FIX-003: 补实现 `calculateBACAfterTime`
- **修于**: 2026-05-11，开发工程师
- **改动**: 新增 `calculateBACAfterTime(initialBAC:hoursPassed:metabolismRate:) → Double`，含 guard 参数校验
- **效果**: 支持线性代谢衰减计算，`max(0, initialBAC - rate × hours)`
- **审查确认**: @reviewer ✅ 确认已修复
