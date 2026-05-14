import SwiftUI

// ============================================================
// 设置页 — 地区法律 / 代谢参数 / 主题 / 重置
// ============================================================

struct SettingsView: View {
    @ObservedObject var vm: SettingsVM

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                regionSection
                metabolismSection
                themeSection
                aboutSection
                dangerZoneSection
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(NeonColors.background.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 地区法律标准

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "location.circle.fill", title: "地区法律标准")

            VStack(spacing: 0) {
                ForEach(LegalRegion.allCases, id: \.rawValue) { region in
                    Button {
                        vm.setRegion(region)
                    } label: {
                        HStack {
                            Text(region.rawValue)
                                .font(.body)
                                .foregroundColor(NeonColors.textPrimary)

                            Spacer()

                            if vm.region == region {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(NeonColors.accent)
                            } else {
                                regionFlag(region)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(
                            vm.region == region
                                ? NeonColors.accent.opacity(0.1)
                                : Color.clear
                        )
                    }

                    if region != LegalRegion.allCases.last {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading)
                    }
                }
            }
            .background(NeonColors.cardBackground)
            .cornerRadius(14)

            // 当前区域法定阈值
            VStack(alignment: .leading, spacing: 8) {
                legalLimitRow(
                    label: "酒后驾驶 (DUI)",
                    limit: vm.region.duiLimit,
                    color: NeonColors.amber
                )
                legalLimitRow(
                    label: "醉酒驾驶 (DWI)",
                    limit: vm.region.duiLimit,
                    color: NeonColors.danger
                )
            }
            .padding()
            .background(NeonColors.cardBackground)
            .cornerRadius(14)
        }
        .neonCard(color: NeonColors.accent.opacity(0.1))
    }

    private func regionFlag(_ region: LegalRegion) -> Text {
        switch region {
        case .cn: return Text("🇨🇳")
        case .us: return Text("🇺🇸")
        case .eu: return Text("🇪🇺")
        }
    }

    private func legalLimitRow(label: String, limit: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundColor(NeonColors.textSecondary)
            Spacer()
            Text("≤ \(String(format: "%.2f", limit * 100)) mg/100ml")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }

    // MARK: - 代谢参数

    private var metabolismSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "bolt.fill", title: "代谢参数")

            VStack(spacing: 16) {
                // 代谢速率滑块
                VStack(spacing: 8) {
                    HStack {
                        Text("代谢速率")
                            .font(.subheadline)
                            .foregroundColor(NeonColors.textSecondary)
                        Spacer()
                        Text(String(format: "%.3f %/h", vm.metabolismRate))
                            .font(.subheadline.bold())
                            .foregroundColor(NeonColors.textPrimary)
                    }

                    Slider(value: $vm.metabolismRate, in: 0.005...0.030, step: 0.001) {
                        Text("代谢速率")
                    }
                    .tint(NeonColors.accent)
                    .onChange(of: vm.metabolismRate) { _, newValue in
                        vm.setMetabolismRate(newValue)
                    }

                    HStack {
                        Text("慢 (0.005)")
                            .font(.caption2)
                            .foregroundColor(NeonColors.textSecondary)
                        Spacer()
                        Text("快 (0.030)")
                            .font(.caption2)
                            .foregroundColor(NeonColors.textSecondary)
                    }
                }

                Divider().background(Color.white.opacity(0.05))

                // 代谢参考信息
                VStack(alignment: .leading, spacing: 8) {
                    Label("默认: 0.015%/h", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(NeonColors.textSecondary)
                    Label("代谢速率因人而异，受基因、肝功能等因素影响",
                          systemImage: "person.fill.questionmark")
                        .font(.caption2)
                        .foregroundColor(NeonColors.textSecondary.opacity(0.7))
                }
            }
            .padding()
            .background(NeonColors.cardBackground)
            .cornerRadius(14)
        }
        .neonCard(color: NeonColors.accent.opacity(0.1))
    }

    // MARK: - 主题

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "paintbrush.fill", title: "主题")

            // 当前主题预览
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NeonColors.background)
                        .overlay(themePreviewContent)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(NeonColors.accent, lineWidth: 2)
                        )

                    Text(AppTheme.neon.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(NeonColors.accent)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .neonCard(color: NeonColors.accent.opacity(0.1))
    }

    private var themePreviewContent: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(NeonColors.neonPurple)
                .frame(width: 20, height: 20)

            Circle()
                .fill(NeonColors.accent)
                .frame(width: 20, height: 20)

            Circle()
                .fill(NeonColors.amber)
                .frame(width: 20, height: 20)
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "info.circle.fill", title: "关于")

            VStack(spacing: 12) {
                aboutRow(label: "应用名称", value: "Alcohol Tolerance")
                Divider().background(Color.white.opacity(0.05))
                aboutRow(label: "版本", value: "1.0.0")
                Divider().background(Color.white.opacity(0.05))
                aboutRow(label: "计算引擎", value: "Widmark 公式")
                Divider().background(Color.white.opacity(0.05))
                aboutRow(label: "免责声明", value: "仅供参考")
            }
            .padding()
            .background(NeonColors.cardBackground)
            .cornerRadius(14)
        }
        .neonCard(color: NeonColors.accent.opacity(0.1))
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(NeonColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(NeonColors.textPrimary)
        }
    }

    // MARK: - 危险操作

    private var dangerZoneSection: some View {
        VStack(spacing: 12) {
            sectionHeader(icon: "exclamationmark.triangle.fill", title: "危险操作", color: NeonColors.danger)

            Button(role: .destructive) {
                vm.resetAllData()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("重置全部数据")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NeonColors.danger)
                )
            }
        }
    }

    // MARK: - 辅助

    private func sectionHeader(icon: String, title: String, color: Color = NeonColors.accent) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(NeonColors.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView(vm: SettingsVM())
        .preferredColorScheme(.dark)
}
