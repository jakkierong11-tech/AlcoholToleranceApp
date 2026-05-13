import SwiftUI

// ============================================================
// KnowledgeView �?饮酒知识科普页面
// 含：Widmark 公式、酒驾标准、影响因素、解酒误�?// ⚠️ 暂未加入主导航，�?Dashboard 快捷卡片进入
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
                    BAC% = (酒精克数 × 100) ÷ (体重g × r) �?β × t

                    �?r = 性别系数（男 0.68 / �?0.55�?                    �?β = 代谢率（�?0.015%/小时�?                    �?酒精克数 = 容量ml × 酒精�? × 0.789

                    该公式是法医学中估算 BAC 的经典方法，但存�?±0.02% 的个体误差�?                    """
                )

                KnowledgeCard(
                    title: "中国酒驾标准",
                    content: """
                    �?饮酒驾驶：BAC �?0.02%�?0mg/100ml�?                    �?醉酒驾驶：BAC �?0.08%�?0mg/100ml�?                    �?醉驾已入刑，最高可判拘�?                    �?吊销驾照�?年内不得重新取得
                    """
                )

                KnowledgeCard(
                    title: "影响 BAC 的因�?,
                    content: """
                    ⬆️ 加速升高：
                    �?空腹饮酒（吸收快 30%�?                    �?碳酸饮料混饮（加速胃排空�?                    �?高度数酒
                    �?快速饮�?
                    ⬇️ 减缓升高�?                    �?进食后饮�?                    �?慢饮
                    �?多喝�?                    """
                )

                KnowledgeCard(
                    title: "解酒误区",
                    content: """
                    �?浓茶解酒 �?咖啡因加重脱�?                    �?抠喉催吐 �?可能引发胰腺�?                    �?冷水�?�?可能引发休克
                    �?强行运动 �?增加心脏负担

                    �?时间是最有效的解酒方�?                    �?多喝水补充水�?                    �?进食易消化食�?                    �?充分休息睡眠
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
            Text("本应用数据仅供参考，不构成医疗或法律建议。饮酒后请勿驾驶�?)
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
