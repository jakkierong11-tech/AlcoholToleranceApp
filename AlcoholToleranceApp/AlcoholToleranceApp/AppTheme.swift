import SwiftUI

// MARK: - App 全局主题

/// 赛博朋克霓虹主题系统
/// 颜色定义来源：BACLevel.colorHex（8 级独立色值）
enum AppTheme: String, Codable, CaseIterable {
    case neon = "赛博朋克"
}

// MARK: - 颜色扩展

extension Color {
    /// 从十六进制字符串创建 Color
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - BACLevel → Color 映射（8 色独立）

extension BACLevel {
    /// SwiftUI Color（每个等级独立颜色，避免 BUG-003）
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - 主题色别名

/// 全局霓虹主题色常量，便于 UI 统一引用
struct NeonColors {
    /// 背景主色（深黑）
    static let background = Color(hex: "#0A0A0F")
    /// 卡片背景
    static let cardBackground = Color(hex: "#1A1A2E")
    /// 主强调色（电光蓝）
    static let accent = Color(hex: "#06B6D4")
    /// 霓虹紫（品牌色/指针色）
    static let neonPurple = Color(hex: "#8B5CF6")
    /// 警告色（霓虹粉）
    static let neonPink = Color(hex: "#EC4899")
    /// 琥珀橙（注意色）
    static let amber = Color(hex: "#F59E0B")
    /// 危险色
    static let danger = Color(hex: "#EF4444")
    /// 安全色（翠绿）
    static let safe = Color(hex: "#10B981")
    /// 文字主色
    static let textPrimary = Color.white
    /// 文字次要色
    static let textSecondary = Color(hex: "#9CA3AF")
    /// 霓虹辉光（用于阴影/发光效果）
    static let glow = Color(hex: "#06B6D4").opacity(0.4)

    // MARK: - 卡片轨道相关

    /// 轨道背景色（深紫黑）
    static let trackBackground = Color(hex: "#1E1E3A")
}

// MARK: - 字体系统

/// 霓虹主题字体常量
struct NeonFonts {
    /// 中文大标题 28pt
    static let titleLarge = Font.custom("PingFang SC", size: 28).weight(.semibold)
    /// 中文小标题 20pt
    static let titleMedium = Font.custom("PingFang SC", size: 20).weight(.medium)
    /// 正文 16pt
    static let body = Font.custom("PingFang SC", size: 16)
    /// 数据等宽 24pt
    static let monoValue = Font.system(size: 24, weight: .bold, design: .monospaced)
    /// 数据等宽 48pt（大数字）
    static let monoLarge = Font.system(size: 48, weight: .heavy, design: .monospaced)
    /// 数据等宽 36pt（仪表盘数字）
    static let monoGauge = Font.system(size: 36, weight: .bold, design: .monospaced)

    // MARK: - Fallback（系统字体）

    static func titleLargeSystem() -> Font { .system(size: 28, weight: .semibold) }
    static func titleMediumSystem() -> Font { .system(size: 20, weight: .medium) }
    static func bodySystem() -> Font { .system(size: 16) }
}

// MARK: - ViewModifier 扩展

/// 霓虹辉光卡片效果
struct NeonCardModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .background(NeonColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// 霓虹卡片样式
    func neonCard(color: Color = NeonColors.accent) -> some View {
        modifier(NeonCardModifier(color: color))
    }
}
