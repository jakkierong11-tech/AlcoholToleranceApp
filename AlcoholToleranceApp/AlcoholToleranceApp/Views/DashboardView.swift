import SwiftUI

// ============================================================
// DashboardView �?主页霓虹仪表�?// 包含�?70° BAC 弧形仪表盘、状态卡片、快速操作入�?// ============================================================

struct DashboardView: View {
    @ObservedObject var vm: DashboardVM

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                bacGaugeSection
                levelInfoCard
                statsGrid
                actionButtons
                soberInfoCard
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(NeonColors.background.ignoresSafeArea())
        .task { vm.refresh() }
    }

    // MARK: - 顶部�?
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("酒量监测")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(NeonColors.textPrimary)
                Text("Alcohol Tolerance Monitor")
                    .font(.caption)
                    .foregroundColor(NeonColors.textSecondary)
            }
            Spacer()
            refreshButton
        }
        .padding(.top, 8)
    }

    private var refreshButton: some View {
        Button { Task { await vm.refresh() } } label: {
            Image(systemName: "arrow.clockwise")
                .font(.body)
                .foregroundColor(NeonColors.accent)
                .frame(width: 40, height: 40)
                .background(Circle().stroke(NeonColors.accent.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - 270° BAC 弧形仪表�?
    private var bacGaugeSection: some View {
        VStack(spacing: 0) {
            ZStack {
                // 背景�?                BACGaugeArc()
                    .stroke(Color.white.opacity(0.08), lineWidth: 24)

                // 渐变弧（从安全色到危险色�?                BACGaugeArc(progress: bacProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: bacGradientColors),
                            center: .center,
                            startAngle: .degrees(-135),
                            endAngle: .degrees(135)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: currentBACColor.opacity(0.6), radius: 12, x: 0, y: 0)

                // 内圈刻度
                BACGaugeArc()
                    .stroke(Color.white.opacity(0.05), lineWidth: 2)
                    .scaleEffect(0.82)

                // 中心显示�?                VStack(spacing: 4) {
                    Text(vm.bacLevel.emoji)
                        .font(.system(size: 40))
                    Text(BACCalculator.formatBAC(vm.currentBAC, style: .mgPer100mL))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(currentBACColor)
                    Text(vm.bacLevel.rawValue)
                        .font(.headline)
                        .foregroundColor(NeonColors.textSecondary)
                }
                .offset(y: -8)

                // 刻度标记
                BACGaugeTickMarks()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .frame(height: 220)
            .padding(.top, 20)
        }
        .neonCard()
        .padding(.horizontal, 4)
    }

    /// BAC 进度值（0.0 ~ 1.0），�?0.40% 为满值（danger 下限�?    private var bacProgress: CGFloat {
        min(CGFloat(vm.currentBAC) / 0.40, 1.0)
    }

    private var currentBACColor: Color {
        vm.bacLevel.color
    }

    private var bacGradientColors: [Color] {
        [
            BACLevel.sober.color,
            BACLevel.mild.color,
            BACLevel.euphoric.color,
            BACLevel.excited.color,
            BACLevel.confused.color,
            BACLevel.stupor.color,
            BACLevel.coma.color,
            BACLevel.danger.color,
        ]
    }

    // MARK: - 等级信息卡片

    private var levelInfoCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(currentBACColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.bacLevel.description)
                    .font(.subheadline)
                    .foregroundColor(NeonColors.textPrimary)

                Text(vm.bacLevel.drivingStatus)
                    .font(.caption)
                    .foregroundColor(currentBACColor)
            }
            Spacer()
        }
        .padding()
        .neonCard(color: currentBACColor)
    }

    // MARK: - 统计网格

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "wineglass",
                value: "\(vm.todayDrinks.count)",
                label: "今日杯数",
                color: NeonColors.accent
            )
            StatCard(
                icon: "star.fill",
                value: String(format: "%.0f", vm.sessionScore),
                label: "耐受评分",
                color: vm.sessionScore >= 60 ? NeonColors.safe : NeonColors.accent
            )
            StatCard(
                icon: "figure.walk",
                value: vm.currentBAC < 0.02 ? "�? : "⚠️",
                label: "驾驶状�?,
                color: vm.currentBAC < 0.02 ? NeonColors.safe : NeonColors.danger
            )
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: 16) {
            NavigationLink {
                DrinkLoggerView()
            } label: {
                ActionButtonLabel(
                    icon: "plus.circle.fill",
                    title: "记录饮酒",
                    subtitle: "添加一杯酒",
                    color: NeonColors.accent
                )
            }

            NavigationLink {
                SoberTestView()
            } label: {
                ActionButtonLabel(
                    icon: "gamecontroller.fill",
                    title: "酒量测试",
                    subtitle: "反应·平衡·记忆",
                    color: NeonColors.safe
                )
            }
        }
    }

    // MARK: - 醒酒信息

    private var soberInfoCard: some View {
        Group {
            if vm.currentBAC > 0.001 {
                let soberHours = BACCalculator.calculateSoberTime(currentBAC: vm.currentBAC)
                let soberDate = BACCalculator.estimatedSoberDate(currentBAC: vm.currentBAC)

                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(NeonColors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("预计醒酒时间")
                            .font(.caption)
                            .foregroundColor(NeonColors.textSecondary)
                        Text(BACCalculator.formatSoberTime(hours: soberHours))
                            .font(.body.bold())
                            .foregroundColor(NeonColors.textPrimary)
                        Text("~ \(soberDate, style: .time)")
                            .font(.caption2)
                            .foregroundColor(NeonColors.textSecondary)
                    }
                    Spacer()
                }
                .padding()
                .neonCard(color: NeonColors.accent)
            }
        }
    }
}

// MARK: - 270° BAC 弧形 Shape

struct BACGaugeArc: Shape {
    var progress: CGFloat = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY - 20)
        let radius = min(rect.width, rect.height * 1.6) / 2 - 12
        let startAngle: Angle = .degrees(-135)
        let endAngle: Angle = .degrees(-135 + 270 * progress)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

// MARK: - 刻度标记

struct BACGaugeTickMarks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY - 20)
        let radius = min(rect.width, rect.height * 1.6) / 2 - 12
        let innerRadius = radius - 16
        let tickCount = 9

        for i in 0...tickCount {
            let angle = Angle.degrees(-135 + 270 * Double(i) / Double(tickCount))
            let outerPos = CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * radius,
                y: center.y + CGFloat(sin(angle.radians)) * radius
            )
            let innerPos = CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * innerRadius,
                y: center.y + CGFloat(sin(angle.radians)) * innerRadius
            )
            path.move(to: outerPos)
            path.addLine(to: innerPos)
        }
        return path
    }
}

// MARK: - 辅助组件

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.system(.title3, design: .monospaced).bold())
                .foregroundColor(NeonColors.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundColor(NeonColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .neonCard(color: color.opacity(0.3))
    }
}

struct ActionButtonLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.bold())
                    .foregroundColor(NeonColors.textPrimary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .neonCard(color: color.opacity(0.25))
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    let container = try! ModelContainer(
        for: User.self, DrinkSession.self, DrinkRecord.self, BACResult.self
    )
    let context = container.mainContext
    let vm = DashboardVM(modelContext: context)
    DashboardView(vm: vm)
        .modelContainer(container)
}
