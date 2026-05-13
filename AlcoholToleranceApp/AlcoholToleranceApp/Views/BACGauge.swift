import SwiftUI

// ============================================================
// BACGauge �?赛博朋克风格 BAC 环形仪表�?// 270° 弧，从底左到底右，顶部留�?// 呼吸光晕�?BAC >= 0.02 时触�?// ============================================================

struct BACGauge: View {
    let bacPercent: Double
    var size: CGFloat = 200

    // MARK: - 动画状�?
    @State private var animationProgress: Double = 0
    @State private var glowOpacity: Double = 0.3

    // MARK: - 计算属�?
    private var bacLevel: BACLevel {
        switch bacPercent {
        case ..<0.020:  return .sober
        case ..<0.035:  return .mild
        case ..<0.060:  return .euphoric
        case ..<0.100:  return .excited
        case ..<0.200:  return .confused
        case ..<0.300:  return .stupor
        case ..<0.400:  return .coma
        default:        return .danger
        }
    }

    private var normalizedBAC: Double {
        min(bacPercent / 0.4, 1.0)
    }

    private var trimEnd: CGFloat {
        0.75 * animationProgress
    }

    private let arcRotation: Double = 135
    private let arcRatio: Double = 0.75

    // MARK: - 颜色

    private var levelColor: Color {
        bacLevel.color
    }

    private var gradientColors: [Color] {
        [
            BACLevel.sober.color,   // #10B981
            BACLevel.mild.color,    // #06B6D4
            BACLevel.euphoric.color, // #8B5CF6
            BACLevel.excited.color, // #F59E0B
            BACLevel.danger.color,  // #EF4444
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 呼吸光晕 (BAC >= 0.02% 触发)
            if bacPercent >= 0.02 {
                Circle()
                    .stroke(levelColor, lineWidth: 12)
                    .blur(radius: 10)
                    .opacity(glowOpacity)
                    .frame(width: size, height: size)
            }

            // 背景轨道
            Circle()
                .trim(from: 0, to: arcRatio)
                .stroke(
                    NeonColors.trackBackground,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(arcRotation))
                .frame(width: size, height: size)

            // 前景进度�?            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(arcRotation))
                .frame(width: size, height: size)

            // 指针（霓虹紫圆点，位于进度末端）
            pointerView

            // 圆心文字
            VStack(spacing: 4) {
                Text(String(format: "%.3f%%", bacPercent))
                    .font(NeonFonts.monoGauge)
                    .foregroundColor(NeonColors.textPrimary)

                Text(bacLevel.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(levelColor)
            }
        }
        .frame(width: size, height: size)
        .onAppear(perform: startAnimations)
        .onChange(of: bacPercent) { _, newBAC in
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = normalizedBAC
            }
            if newBAC >= 0.02 {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.6
                }
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    glowOpacity = 0
                }
            }
        }
    }

    // MARK: - 指针

    private var pointerView: some View {
        let radius = size / 2 - 6
        let angleDeg = arcRotation + (360 * arcRatio) * animationProgress
        let angleRad = Angle.degrees(angleDeg).radians

        return Circle()
            .fill(NeonColors.neonPurple)
            .frame(width: 10, height: 10)
            .shadow(color: NeonColors.neonPurple.opacity(0.6), radius: 4)
            .offset(
                x: radius * cos(angleRad),
                y: -radius * sin(angleRad)
            )
    }

    // MARK: - 动画

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animationProgress = normalizedBAC
        }
        if bacPercent >= 0.02 {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
    }
}

// MARK: - Preview

#Preview("清醒") {
    BACGauge(bacPercent: 0.005, size: 200)
        .padding()
        .background(NeonColors.background)
        .preferredColorScheme(.dark)
}

#Preview("微醺 + 呼吸") {
    BACGauge(bacPercent: 0.045, size: 200)
        .padding()
        .background(NeonColors.background)
        .preferredColorScheme(.dark)
}

#Preview("高危") {
    BACGauge(bacPercent: 0.12, size: 200)
        .padding()
        .background(NeonColors.background)
        .preferredColorScheme(.dark)
}
