import SwiftUI

// ============================================================
// 饮酒记录视图 — 选择酒类 + 调整用量 + 记录到日志
// ============================================================

struct DrinkLoggerView: View {
    @ObservedObject var vm: DrinkLoggerVM

    init() {
        _vm = ObservedObject(wrappedValue: DrinkLoggerVM(modelContext: DataStack.shared.container.mainContext))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                sessionHeader
                drinkTypeGrid
                volumeSection
                abvSection
                optionToggles
                actionButtons
                currentSessionSummary
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(NeonColors.background.ignoresSafeArea())
        .navigationTitle("记录饮酒")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 会话状态头部指示
    private var sessionHeader: some View {
        HStack {
            switch vm.state {
            case .idle, .recording:
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("正在记录")
                        .font(.subheadline)
                        .foregroundColor(NeonColors.textSecondary)
                }
            case .done:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NeonColors.safe)
                    Text("已记录")
                        .font(.subheadline)
                        .foregroundColor(NeonColors.safe)
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - 酒类选择

    private var drinkTypeGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择酒类")
                .font(.callout.bold())
                .foregroundColor(NeonColors.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                ForEach(DrinkType.allCases, id: \.rawValue) { type in
                    drinkTypeButton(type)
                }
            }
        }
    }

    private func drinkTypeButton(_ type: DrinkType) -> some View {
        Button {
            vm.setDrinkType(type)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.title3)
                    .foregroundColor(vm.selectedType == type ? .white : NeonColors.accent)

                Text(type.rawValue)
                    .font(.caption2)
                    .foregroundColor(vm.selectedType == type ? .white : NeonColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(vm.selectedType == type
                          ? NeonColors.accent
                          : NeonColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(vm.selectedType == type
                            ? NeonColors.accent
                            : Color.white.opacity(0.1),
                            lineWidth: 1)
            )
            .shadow(color: vm.selectedType == type
                    ? NeonColors.glow
                    : .clear, radius: 6)
        }
    }

    /// 饮用量选择区域
    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("饮用量")
                .font(.callout.bold())
                .foregroundColor(NeonColors.textSecondary)

            HStack {
                Text(String(format: "%.0f", vm.volumeMl))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(NeonColors.textPrimary)
                Text("ml")
                    .font(.body)
                    .foregroundColor(NeonColors.textSecondary)
                Spacer()
            }

            Slider(value: $vm.volumeMl, in: 50...1000, step: 10)
                .tint(NeonColors.accent)

            HStack {
                Text("50ml")
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
                Spacer()
                Text("1000ml")
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
            }
        }
        .padding()
        .neonCard()
    }

    // MARK: - 酒精度数

    private var abvSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("酒精度数 (ABV%)")
                .font(.callout.bold())
                .foregroundColor(NeonColors.textSecondary)

            HStack {
                Text(String(format: "%.1f", vm.abv))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(NeonColors.textPrimary)
                Text("%")
                    .font(.body)
                    .foregroundColor(NeonColors.textSecondary)
                Spacer()

                Text(vm.selectedType.typicalVolumeMl > 0 ? "默认: \(String(format: "%.0f", vm.selectedType.typicalVolumeMl))ml" : "")
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
            }

            Slider(value: $vm.abv, in: 0.5...95, step: 0.5)
                .tint(NeonColors.accent)

            HStack {
                Text("0.5%")
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
                Spacer()
                Text("95%")
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
            }

            if vm.abv != vm.selectedType.defaultAbv {
                Text("已偏离默认值 (\(vm.selectedType.rawValue) 默认 \(String(format: "%.1f", vm.selectedType.defaultAbv))%)")
                    .font(.caption2)
                    .foregroundColor(NeonColors.accent)
            }
        }
        .padding()
        .neonCard()
    }

    /// 附加选项（碳酸/空腹）
    private var optionToggles: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $vm.isCarbonated) {
                HStack(spacing: 8) {
                    Image(systemName: "bubbles.and.sparkles.fill")
                        .foregroundColor(vm.isCarbonated ? NeonColors.accent : .gray)
                    Text("含气饮品 (×1.2 系数)")
                        .font(.subheadline)
                        .foregroundColor(NeonColors.textPrimary)
                }
            }
            .tint(NeonColors.accent)

            Divider()
                .background(Color.white.opacity(0.1))

            Toggle(isOn: $vm.isEmptyStomach) {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(vm.isEmptyStomach ? NeonColors.accent : .gray)
                    Text("空腹饮酒 (×1.3 系数)")
                        .font(.subheadline)
                        .foregroundColor(NeonColors.textPrimary)
                }
            }
            .tint(NeonColors.accent)
        }
        .padding()
        .neonCard()
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                vm.logDrink()
            } label: {
                HStack {
                    Image(systemName: "wineglass.fill")
                    Text("记录这杯")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NeonColors.accent)
                )
                .shadow(color: NeonColors.glow, radius: 12, x: 0, y: 4)
            }

            if vm.state == .done {
                Button(role: .destructive) {
                    vm.cancelLastDrink()
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("撤回上杯")
                    }
                    .font(.subheadline)
                    .foregroundColor(NeonColors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(NeonColors.danger.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - 当前会话摘要

    private var currentSessionSummary: some View {
        HStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.title2)
                .foregroundColor(NeonColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("关于剂量")
                    .font(.caption)
                    .foregroundColor(NeonColors.textSecondary)

                let stdDrinks = BACCalculator.calculateStandardDrinks(
                    volumeML: vm.volumeMl,
                    alcoholPercent: vm.abv
                )
                Text("标准单位: \(String(format: "%.1f", stdDrinks))")
                    .font(.subheadline.bold())
                    .foregroundColor(NeonColors.textPrimary)

                Text("纯酒精: \(String(format: "%.1f", vm.volumeMl * (vm.abv / 100) * 0.789))g")
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .neonCard(color: NeonColors.accent.opacity(0.2))
    }
}

// MARK: - Preview

#Preview("DrinkLogger") {
    DrinkLoggerView()
        .preferredColorScheme(.dark)
}
