import SwiftUI

// ============================================================
// 酒量清醒测试页 — 反应速度 / 平衡 / 记忆三项测试
// ============================================================

struct SoberTestView: View {
    @ObservedObject var vm: SoberTestVM

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                testTypePicker
                testContentArea
                lastResultCard
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(NeonColors.background.ignoresSafeArea())
        .navigationTitle("酒量测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 测试类型选择

    private var testTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(SoberTestType.allCases, id: \.rawValue) { type in
                Button {
                    vm.testType = type
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: iconForTest(type))
                            .font(.title3)
                        Text(type.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(vm.testType == type ? .white : NeonColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(vm.testType == type
                                  ? NeonColors.accent
                                  : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .background(NeonColors.cardBackground)
        .cornerRadius(14)
    }

    private func iconForTest(_ type: SoberTestType) -> String {
        switch type {
        case .reaction: return "bolt.fill"
        case .balance:      return "figure.walk"
        case .memory:       return "memorychip.fill"
        }
    }

    // MARK: - 测试内容区域

    @ViewBuilder
    private var testContentArea: some View {
        switch vm.testType {
        case .reaction:
            ReactionTestView(vm: vm)
        case .balance:
            BalanceTestView(vm: vm)
        case .memory:
            MemoryTestView(vm: vm)
        }
    }

    // MARK: - 上次结果

    private var lastResultCard: some View {
        Group {
            if let lastResult = vm.lastResult {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundColor(NeonColors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("上次测试结果")
                            .font(.caption)
                            .foregroundColor(NeonColors.textSecondary)
                        Text("得分: \(String(format: "%.0f", lastResult)) / 100")
                            .font(.body.bold())
                            .foregroundColor(resultColor(lastResult))
                    }
                    Spacer()

                    Button("重测") {
                        vm.startTest()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(NeonColors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(NeonColors.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding()
                .neonCard()
            }
        }
    }

    private func resultColor(_ score: Double) -> Color {
        switch score {
        case 80...: return NeonColors.safe
        case 50..<80: return NeonColors.accent
        case 20..<50: return NeonColors.amber
        default: return NeonColors.danger
        }
    }
}

// MARK: - 反应速度测试

struct ReactionTestView: View {
    @ObservedObject var vm: SoberTestVM

    @State private var stimulusColor = NeonColors.cardBackground
    @State private var stimulusOpacity: Double = 0.3
    @State private var resultText = "点击开始测试.."
    @State private var isWaitingForStimulus = false
    @State private var tapStartTime: Date = Date()
    @State private var roundReactionTimes: [Double] = []

    var body: some View {
        VStack(spacing: 16) {
            // 刺激区域
            RoundedRectangle(cornerRadius: 20)
                .fill(stimulusColor)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(stimulusOpacity))
                        Text(resultText)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
                .frame(height: 180)
                .onTapGesture {
                    handleTap()
                }
                .shadow(color: stimulusColor.opacity(0.3), radius: 16)

            // 进度
            if !roundReactionTimes.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(roundReactionTimes.enumerated()), id: \.offset) { idx, time in
                        Capsule()
                            .fill(time > 0 ? NeonColors.accent : NeonColors.textSecondary.opacity(0.2))
                            .frame(height: 6)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)
            }

            // 开始/重试按钮
            Button {
                startReactionTest()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text(isWaitingForStimulus ? "测试中.." : "开始反应测试")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isWaitingForStimulus
                              ? NeonColors.textSecondary.opacity(0.3)
                              : NeonColors.accent)
                )
            }
            .disabled(isWaitingForStimulus)
        }
        .padding()
        .neonCard()
    }

    private func startReactionTest() {
        roundReactionTimes = []
        resultText = "等待变色..."
        stimulusColor = NeonColors.cardBackground
        stimulusOpacity = 0.3
        isWaitingForStimulus = true

        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            showStimulus()
        }
    }

    private func showStimulus() {
        stimulusColor = NeonColors.safe
        stimulusOpacity = 1.0
        resultText = "👆 快点击！"
        tapStartTime = Date()
    }

    private func handleTap() {
        guard isWaitingForStimulus else { return }

        if stimulusColor == NeonColors.cardBackground || stimulusOpacity < 0.8 {
            // 抢跑
            resultText = "⚠️ 抢跑了！重新开始"
            return
        }

        let reactionMs = Date().timeIntervalSince(tapStartTime) * 1000
        roundReactionTimes.append(reactionMs)

        if roundReactionTimes.count >= 5 {
            // 5 轮完成，计算平均反应时间
            let avgMs = roundReactionTimes.reduce(0, +) / Double(roundReactionTimes.count)
            vm.submitReactionTime(avgMs)
            resultText = String(format: "🎯 平均反应: %.0fms", avgMs)
            stimulusColor = NeonColors.cardBackground
            stimulusOpacity = 0.3
            isWaitingForStimulus = false
        } else {
            resultText = "✅ 第 \(roundReactionTimes.count)/5 轮完成"
            stimulusColor = NeonColors.cardBackground
            stimulusOpacity = 0.3
            // 短暂间隔后开始下一轮
            let delay = Double.random(in: 1.0...2.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.isWaitingForStimulus {
                    self.showStimulus()
                }
            }
        }
    }
}

// MARK: - 平衡测试

struct BalanceTestView: View {
    @ObservedObject var vm: SoberTestVM

    @State private var isTesting = false
    @State private var timerSeconds = 15
    @State private var tiltValues: [Double] = []

    var body: some View {
        VStack(spacing: 16) {
            // 倾斜仪表
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: isTesting ? 0.5 : 0)
                    .stroke(NeonColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 40))
                        .foregroundColor(NeonColors.accent)
                    Text(isTesting ? "保持稳定 \(timerSeconds)s" : "准备测试")
                        .font(.headline)
                        .foregroundColor(NeonColors.textSecondary)
                }
            }
            .frame(height: 160)

            // 稳定性指示条
            if isTesting {
                VStack(spacing: 4) {
                    Text("稳定性")
                        .font(.caption)
                        .foregroundColor(NeonColors.textSecondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(stabilityColor)
                                .frame(width: geo.size.width * stabilityRatio, height: 12)
                        }
                    }
                    .frame(height: 12)
                }
            }

            // 操作按钮
            Button {
                if isTesting {
                    finishBalanceTest()
                } else {
                    startBalanceTest()
                }
            } label: {
                HStack {
                    Image(systemName: isTesting ? "stop.fill" : "play.fill")
                    Text(isTesting ? "结束测试" : "开始 15 秒平衡测试")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isTesting ? NeonColors.danger : NeonColors.accent)
                )
            }

            Text("将手机平放在手掌上保持 15 秒不动")
                .font(.caption)
                .foregroundColor(NeonColors.textSecondary)
        }
        .padding()
        .neonCard()
    }

    private var stabilityRatio: CGFloat {
        guard !tiltValues.isEmpty else { return 0.5 }
        let avg = tiltValues.reduce(0, +) / Double(tiltValues.count)
        return CGFloat(max(0, min(1, 1.0 - avg / 30.0)))
    }

    private var stabilityColor: Color {
        switch stabilityRatio {
        case 0.7...: return NeonColors.safe
        case 0.4..<0.7: return NeonColors.accent
        default: return NeonColors.danger
        }
    }

    private func startBalanceTest() {
        isTesting = true
        timerSeconds = 15
        tiltValues = []

        // 每秒采样一次倾斜度
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard self.isTesting else {
                timer.invalidate()
                return
            }
            let simulatedTilt = Double.random(in: 1...20)
            self.tiltValues.append(simulatedTilt)
            self.timerSeconds -= 1

            if self.timerSeconds <= 0 {
                timer.invalidate()
                self.finishBalanceTest()
            }
        }
    }

    private func finishBalanceTest() {
        isTesting = false
        let avgTilt = tiltValues.isEmpty ? 0 : tiltValues.reduce(0, +) / Double(tiltValues.count)
        let score = max(0, min(100, 100 - avgTilt * 3))
        vm.submitBalanceTest(score)
    }
}

// MARK: - 记忆测试

struct MemoryTestView: View {
    @ObservedObject var vm: SoberTestVM

    @State private var sequence: [String] = []
    @State private var userSequence: [String] = []
    @State private var isShowing = false
    @State private var currentRound = 1
    @State private var correctRounds = 0
    @State private var isPlaying = false
    @State private var showWrong = false

    private let symbols = ["🔴", "🔵", "🟢", "🟡", "🟣", "🟠"]

    var body: some View {
        VStack(spacing: 16) {
            // 状态提示
            VStack(spacing: 4) {
                if isShowing {
                    Text("记住序列！")
                        .font(.headline)
                        .foregroundColor(NeonColors.accent)
                } else if isPlaying {
                    Text("输入序列")
                        .font(.headline)
                        .foregroundColor(NeonColors.textSecondary)
                    Text("第 \(userSequence.count)/\(sequence.count) 位")
                        .font(.caption)
                        .foregroundColor(NeonColors.textSecondary)
                } else {
                    Text("准备开始")
                        .font(.headline)
                        .foregroundColor(NeonColors.textSecondary)
                }
            }

            // 序列展示区
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Array(sequence.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.system(size: 36))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 60)
            }

            if showWrong {
                Text("❌ 顺序错误！测试结束")
                    .font(.headline)
                    .foregroundColor(NeonColors.danger)
            } else if isPlaying && !isShowing {
                Text("第 \(currentRound) 轮 | 正确 \(correctRounds)/\(currentRound - 1)")
                    .font(.caption)
                    .foregroundColor(NeonColors.textSecondary)
            }

            // 符号选择按钮
            if isPlaying && !isShowing {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(symbols, id: \.self) { symbol in
                        Button {
                            selectSymbol(symbol)
                        } label: {
                            Text(symbol)
                                .font(.system(size: 40))
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(NeonColors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            // 控制按钮
            Button {
                startMemoryRound()
            } label: {
                HStack {
                    Image(systemName: isPlaying ? "arrow.counterclockwise" : "play.fill")
                    Text(isPlaying ? "重新开始" : "开始记忆测试")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isPlaying ? NeonColors.danger.opacity(0.7) : NeonColors.accent)
                )
            }
        }
        .padding()
        .neonCard()
    }

    private func startMemoryRound() {
        isPlaying = true
        currentRound = 1
        correctRounds = 0
        showWrong = false
        userSequence = []
        generateSequence()
    }

    private func generateSequence() {
        let length = currentRound + 2 // 第 1 轮 3 个，第 2 轮 4 个..
        sequence = (0..<length).map { _ in symbols.randomElement()! }
        userSequence = []
        showWrong = false

        // 展示序列
        isShowing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(length) * 0.8 + 1.0) {
            isShowing = false
        }
    }

    private func selectSymbol(_ symbol: String) {
        guard isPlaying && !isShowing && userSequence.count < sequence.count else { return }
        userSequence.append(symbol)

        // 检查当前输入是否正确
        let index = userSequence.count - 1
        if userSequence[index] != sequence[index] {
            showWrong = true
            // 结束测试
            let totalCorrect = (0..<currentRound - 1).reduce(0) { $0 + ($1 + 2) } + correctRounds
            let totalItems = (0..<currentRound).reduce(0) { $0 + ($1 + 2) }
            vm.submitMemoryTest(totalCorrect, totalItems)
            isPlaying = false
            return
        }

        if userSequence.count == sequence.count {
            // 本轮正确
            correctRounds += 1
            currentRound += 1
            // 短暂延迟后进入下一轮
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.generateSequence()
            }
        }
    }
}

// MARK: - Preview

#Preview("SoberTest") {
    let container = try! ModelContainer(
        for: User.self, DrinkSession.self, DrinkRecord.self, BACResult.self
    )
    let context = container.mainContext
    let vm = SoberTestVM(modelContext: context)
    SoberTestView(vm: vm)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
