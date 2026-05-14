import SwiftUI

// ============================================================
// 饮酒知识页 — Widmark 公式 + 酒驾标准 + 影响因素 + 解酒误区
// ============================================================

struct KnowledgeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("🍺 饮酒知识")
                    .font(NeonFonts.titleLarge)
                    .foregroundColor(NeonColors.textPrimary)
                    .padding(.top)

                KnowledgeCard(
                    title: "Widmark 公式",
                    content: """
                    BAC% = (酒精克数 / (体重g × r)) × 100 - β × t

                    其中：
                    • r = 男性 0.68 / 女性 0.55（分布系数）
                    • β = 平均代谢速率 0.015%/h
                    • 酒精克数 = 饮用量(ml) × 酒精度(%) × 0.789

                    中国法律 BAC ≥ 0.02% 即构成酒驾
                    """
                )

                KnowledgeCard(
                    title: "中国酒驾标准",
                    content: """
                    🟡 饮酒驾驶：BAC ≥ 0.02%（20mg/100ml）
                    🔴 醉酒驾驶：BAC ≥ 0.08%（80mg/100ml）

                    处罚：
                    • 酒驾：暂扣驾照 6 个月 + 罚款
                    • 醉驾：吊销驾照 + 刑事责任
                    • 营运车辆处罚更重
                    """
                )

                KnowledgeCard(
                    title: "影响 BAC 的因素",
                    content: """
                    ⬆️ 加速升高：
                    • 空腹饮酒（吸收加快约 30%）
                    • 含气饮品（碳酸加速吸收）
                    • 快速大量饮用
                    • 空腹 + 高浓度酒

                    ⬇️ 减缓升高：
                    • 进食后饮酒
                    • 缓慢小口饮用
                    • 多喝水稀释
                    • 搭配食物
                    """
                )

                KnowledgeCard(
                    title: "解酒误区",
                    content: """
                    ❌ 浓茶/咖啡不能解酒 — 只是提神
                    ❌ 冷水澡不能加速代谢 — 可能引发休克
                    ❌ 催吐不减少已吸收的酒精 — 仅排出胃中残留

                    ✅ 唯一有效方式：
                    • 等待肝脏自然代谢（约 0.015%/h）
                    • 充足休息 + 补充水分
                    • 时间是最好的解酒药
                    """
                )

                DisclaimerBox()
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(NeonColors.background.ignoresSafeArea())
        .navigationTitle("饮酒知识")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 知识卡片

struct KnowledgeCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(NeonColors.neonPurple)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(NeonColors.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NeonColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NeonColors.neonPurple.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - 免责声明

struct DisclaimerBox: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(NeonColors.amber)
            Text("以上内容仅供参考，不构成医疗或法律建议。请理性饮酒，酒后不开车。")
                .font(.caption2)
                .foregroundColor(NeonColors.textSecondary)
        }
        .padding()
        .background(NeonColors.cardBackground.opacity(0.5))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview("Knowledge") {
    NavigationStack {
        KnowledgeView()
            .preferredColorScheme(.dark)
    }
}
