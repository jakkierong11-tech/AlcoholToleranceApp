import SwiftUI

// ============================================================
// [corrupted comment removed]
// [corrupted comment removed]
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
                    BAC% = (/*?*/ /*?*/ 100) /*?*/ (/*?*/g /*?*/ r) /*?*/?/*?*/ /*?*/ t

                    /*?*/?r = /*?*/ 0.68 / /*?*/?0.55/*?*/?                    /*?*/?/*?*/ = /*?*/?0.015%//*?*/?                    /*?*/?/*?*/ = /*?*/ml /*?*/ /*?*/? /*?*/ 0.789

                    /*?*/ BAC /*?*/?/*?*/0.02% /*?*/?                    """
                )

                KnowledgeCard(
                    title: "中国酒驾标准",
                    content: """
                    /*?*/?/*?*/BAC /*?*/?0.02%/*?*/?0mg/100ml/*?*/?                    /*?*/?/*?*/BAC /*?*/?0.08%/*?*/?0mg/100ml/*?*/?                    /*?*/?/*?*/?                    /*?*/?/*?*/?/*?*/
                    """
                )

                KnowledgeCard(
                    title: "/*?*/ BAC /*?*/?,
                    content: """
                    ⬆️ 加速升高：
                    /*?*/?/*?*/ 30%/*?*/?                    /*?*/?/*?*/?                    /*?*/?/*?*/
                    /*?*/?/*?*/?
                    /*?*/ /*?*/?                    /*?*/?/*?*/?                    /*?*/?/*?*/
                    /*?*/?/*?*/?                    """
                )

                KnowledgeCard(
                    title: "解酒误区",
                    content: """
                    /*?*/?/*?*/ /*?*/?/*?*/?                    /*?*/?/*?*/ /*?*/?/*?*/?                    /*?*/?/*?*/?/*?*/?/*?*/
                    /*?*/?/*?*/ /*?*/?/*?*/

                    /*?*/?/*?*/?                    /*?*/?/*?*/?                    /*?*/?/*?*/?                    /*?*/?/*?*/
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
            Text("/*?*/?)
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
