import SwiftUI

// ============================================================
// [corrupted comment removed]
// [corrupted comment removed]

struct ProfileView: View {
    @ObservedObject var vm: ProfileVM

    @State private var showEditSheet = false
    @State private var showResetAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                userHeaderCard
                statsSection
                titleSection
                editButton
                resetButton
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(NeonColors.background.ignoresSafeArea())
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .task { vm.loadProfile() }
        .sheet(isPresented: $showEditSheet) {
            ProfileEditView(vm: vm)
        }
        .alert("/*?*/?, isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("确认重置", role: .destructive) { vm.resetAllData() }
        } message: {
            Text("/*?*/?)
        }
    }

    // MARK: - 用户头像卡片

    private var userHeaderCard: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(NeonColors.cardBackground)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(NeonColors.accent.opacity(0.3), lineWidth: 2)
                    )

                Text(userInitials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(NeonColors.accent)
            }

            // 昵称
            Text(vm.user.nickname)
                .font(.title2.bold())
                .foregroundColor(NeonColors.textPrimary)

            // 性别年龄
            HStack(spacing: 16) {
                Label(
                    vm.user.isMale ? "/*?*/? : "/*?*/?,
                    systemImage: vm.user.isMale ? "figure.stand" : "figure.stand.dress"
                )
                Label("\(vm.user.estimatedAge)/*?*/?, systemImage: "calendar")
                Label(String(format: "%.0f kg", vm.user.weightKg), systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundColor(NeonColors.textSecondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .neonCard(color: NeonColors.accent.opacity(0.2))
    }

    private var userInitials: String {
        let name = vm.user.nickname
        if name.count >= 2 {
            return String(name.suffix(2))
        }
        return String(name.prefix(1))
    }

    // MARK: - 统计数据

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "star.fill",
                value: String(format: "%.0f", vm.highestScore),
                label: "最高分",
                color: traitColor(vm.highestScore)
            )
            StatCard(
                icon: "clock.fill",
                value: "\(vm.totalSessions)",
                label: "/*?*/?,
                color: NeonColors.accent
            )
            StatCard(
                icon: "crown.fill",
                value: vm.title.prefix(1) == "🍼" ? "新手" : "老手",
                label: "阶段",
                color: vm.totalSessions > 10 ? NeonColors.safe : NeonColors.textSecondary
            )
        }
    }

    private func traitColor(_ score: Double) -> Color {
        switch score {
        case 80...: return NeonColors.amber
        case 60..<80: return NeonColors.safe
        case 30..<60: return NeonColors.accent
        default: return NeonColors.textSecondary
        }
    }

    // MARK: - 称号展示

    private var titleSection: some View {
        HStack(spacing: 16) {
            // 称号 emoji
            Text(titleEmoji)
                .font(.system(size: 44))

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.title)
                    .font(.headline.bold())
                    .foregroundColor(NeonColors.textPrimary)

                Text(titleDescription)
                    .font(.caption)
                    .foregroundColor(NeonColors.textSecondary)

// [corrupted comment removed]
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(titleProgressColor)
                            .frame(width: geo.size.width * titleProgress, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.top, 4)

                Text("/*?*/? \(String(format: "%.0f", nextTitleThreshold - vm.highestScore)) /*?*/?)
                    .font(.caption2)
                    .foregroundColor(NeonColors.textSecondary)
            }
        }
        .padding()
        .neonCard(color: titleProgressColor.opacity(0.2))
    }

    private var titleEmoji: String {
        switch vm.highestScore {
        case ..<20:  return "🍼"
        case ..<40:  return "🍺"
        case ..<60:  return "🍷"
        case ..<80:  return "🥃"
        case ..<95:  return "🍾"
        default:     return "👑"
        }
    }

    private var titleDescription: String {
        UserManager.getUserTitle(for: vm.highestScore).description
    }

    private var titleProgress: CGFloat {
        let raw = CGFloat(vm.highestScore) / 100.0
        return min(max(raw, 0), 1.0)
    }

    private var titleProgressColor: Color {
        switch vm.highestScore {
        case ..<20:  return NeonColors.accent
        case ..<60:  return NeonColors.safe
        case ..<95:  return NeonColors.amber
        default:     return NeonColors.neonPurple
        }
    }

    private var nextTitleThreshold: Double {
        switch vm.highestScore {
        case ..<20:  return 20
        case ..<40:  return 40
        case ..<60:  return 60
        case ..<80:  return 80
        case ..<95:  return 95
        default:     return 100
        }
    }

    // MARK: - 编辑按钮

    private var editButton: some View {
        Button {
            showEditSheet = true
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("编辑资料")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonColors.accent)
            )
            .shadow(color: NeonColors.glow, radius: 10)
        }
    }

    // MARK: - 重置按钮

    private var resetButton: some View {
        Button(role: .destructive) {
            showResetAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("/*?*/?)
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

// MARK: - 资料编辑 Sheet

struct ProfileEditView: View {
    @ObservedObject var vm: ProfileVM
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var weightText: String = ""
    @State private var isMale: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("昵称", text: $nickname)
                        .onAppear { nickname = vm.user.nickname }

                    HStack {
                        Text("体重 (kg)")
                        TextField("体重", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onAppear {
                                weightText = String(format: "%.0f", vm.user.weightKg)
                            }
                    }

                    Picker("性别", selection: $isMale) {
                        Text("/*?*/?).tag(true)
                        Text("/*?*/?).tag(false)
                    }
                    .onAppear { isMale = vm.user.isMale }
                }

                Section {
                    Button("保存修改") {
                        saveChanges()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(NeonColors.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NeonColors.background)
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(NeonColors.accent)
                }
            }
        }
    }

    private func saveChanges() {
        if !nickname.trimmingCharacters(in: .whitespaces).isEmpty {
            vm.updateNickname(nickname)
        }
        if let weight = Double(weightText), weight > 0 {
            vm.updateWeight(weight)
        }
        vm.updateGender(isMale)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Profile") {
    let container = try! ModelContainer(
        for: User.self, DrinkSession.self, DrinkRecord.self, BACResult.self
    )
    let context = container.mainContext
    let userManager = UserManager(modelContext: context)
    let vm = ProfileVM(userManager: userManager)

    // 设置示例数据
    let user = userManager.fetchOrCreateUser()
    user.highestScore = 42
    user.totalTests = 15
    try? userManager.updateProfile(user: user)
    vm.loadProfile()

    return NavigationStack {
        ProfileView(vm: vm)
            .modelContainer(container)
            .preferredColorScheme(.dark)
    }
}
