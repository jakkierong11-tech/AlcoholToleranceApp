import SwiftUI

// ============================================================
// [corrupted comment removed]
// 展示过往饮酒会话列表，支持筛选、删除、详情展开
// ============================================================

struct HistoryView: View {
    @ObservedObject var vm: HistoryVM

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            sessionList
        }
        .background(NeonColors.background.ignoresSafeArea())
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadHistory() }
    }

    // MARK: - 筛选栏

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryFilter.allCases, id: \.rawValue) { filter in
                    Button {
                        vm.applyFilter(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(vm.filter == filter ? .bold : .regular)
                            .foregroundColor(vm.filter == filter ? .white : NeonColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(vm.filter == filter
                                          ? NeonColors.accent
                                          : NeonColors.cardBackground)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: - 会话列表

    @ViewBuilder
    private var sessionList: some View {
        if vm.isLoading {
            Spacer()
            ProgressView()
                .tint(NeonColors.accent)
            Spacer()
        } else if vm.sessions.isEmpty {
            emptyState
        } else {
            List {
                ForEach(vm.sessions, id: \.id) { session in
                    SessionRow(session: session)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.deleteSession(session.id)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
// [corrupted comment removed]
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await vm.loadHistory() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(NeonColors.textSecondary.opacity(0.4))

            Text("/*?*/?)
                .font(.title3.bold())
                .foregroundColor(NeonColors.textPrimary)

            Text("/*?*/?)
                .font(.subheadline)
                .foregroundColor(NeonColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// [corrupted comment removed]
struct SessionRow: View {
    let session: DrinkSession

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 左边：BAC 等级 emoji
                Text(bacEmoji)
                    .font(.system(size: 36))

// [corrupted comment removed]
                    // 日期
                    Text(session.startTime, style: .date)
                        .font(.subheadline.bold())
                        .foregroundColor(NeonColors.textPrimary)

                    HStack(spacing: 6) {
                        Label("\(session.drinkRecords.count)", systemImage: "wineglass")
                            .font(.caption)
                            .foregroundColor(NeonColors.textSecondary)

                        if let result = session.bacResult {
                            Text("/*?*/?)
                                .foregroundColor(NeonColors.textSecondary)

                            Text(BACCalculator.formatBAC(result.bacPercent))
                                .font(.caption)
                                .foregroundColor(bacColor)

                            Text("/*?*/?)
                                .foregroundColor(NeonColors.textSecondary)

                            Text("\(String(format: "%.0f", result.toleranceScore))/*?*/?)
                                .font(.caption)
                                .foregroundColor(scoreColor)
                        }
                    }
                }

                Spacer()

// [corrupted comment removed]
                    .font(.caption)
                    .foregroundColor(NeonColors.textSecondary.opacity(0.5))
            }
            .padding()
            .background(NeonColors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(bacColor.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }

    private var bacEmoji: String {
        session.bacResult?.level.emoji ?? "🍺"
    }

    private var bacColor: Color {
        session.bacResult?.level.color ?? NeonColors.textSecondary
    }

    private var scoreColor: Color {
        guard let score = session.bacResult?.toleranceScore else { return NeonColors.textSecondary }
        switch score {
        case 60...: return NeonColors.safe
        case 30..<60: return NeonColors.accent
        default: return NeonColors.textSecondary
        }
    }
}

// MARK: - Preview

#Preview("History") {
    let container = try! ModelContainer(
        for: User.self, DrinkSession.self, DrinkRecord.self, BACResult.self
    )
    let context = container.mainContext
    let vm = HistoryVM(modelContext: context)

    // 添加示例数据
    let user = UserManager(modelContext: context).fetchOrCreateUser()
    vm.setUser(user)
    let sessionManager = DrinkSessionManager(modelContext: context)
    let session = sessionManager.startSession(user: user)
    try? sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
    try? sessionManager.addDrink(to: session, type: .wine, volumeML: 200)
    try? sessionManager.endSession(session)
    vm.loadAll()

    return NavigationStack {
        HistoryView(vm: vm)
            .modelContainer(container)
            .preferredColorScheme(.dark)
    }
}
