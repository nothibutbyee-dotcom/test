import SwiftUI
import UIKit

@main
struct MisakiLarpApp: App {
    var body: some Scene {
        WindowGroup {
            MisakiView()
        }
    }
}

struct MisakiTheme {
    let name: String
    let top: Color
    let bottom: Color
}

struct MisakiView: View {
    enum Phase { case idle, running, done }

    // Settings (saved on the device)
    @AppStorage("themeIndex") private var themeIndex = 0
    @AppStorage("accentIndex") private var accentIndex = 0
    @AppStorage("respringSeconds") private var respringSeconds = 6.0
    @AppStorage("haptics") private var haptics = true
    @AppStorage("lockAfterRespring") private var lockAfterRespring = true
    @AppStorage("logUsesAccent") private var logUsesAccent = false

    // Jailbreak tab
    @State private var phase: Phase = .idle
    @State private var progress: Double = 0
    @State private var logs: [String] = []
    @State private var blackout = false
    @State private var showConfirm = false
    @State private var showLock = false

    // Exploit tab
    @State private var exploit = 0
    @State private var luck: Double = 50
    @State private var disablePAC = true
    @State private var summonCat = false
    @State private var offsets: [String] = []

    private let exploits = ["kfd", "landa", "misakipwn"]

    private let themes: [MisakiTheme] = [
        MisakiTheme(name: "Midnight",
                    top: Color(red: 0.12, green: 0.04, blue: 0.20),
                    bottom: Color(red: 0.02, green: 0.02, blue: 0.06)),
        MisakiTheme(name: "Ocean",
                    top: Color(red: 0.02, green: 0.14, blue: 0.28),
                    bottom: Color(red: 0.01, green: 0.03, blue: 0.08)),
        MisakiTheme(name: "Sunset",
                    top: Color(red: 0.32, green: 0.08, blue: 0.16),
                    bottom: Color(red: 0.06, green: 0.02, blue: 0.06)),
        MisakiTheme(name: "Matrix",
                    top: Color(red: 0.00, green: 0.14, blue: 0.06),
                    bottom: Color(red: 0.00, green: 0.03, blue: 0.01)),
        MisakiTheme(name: "Graphite",
                    top: Color(red: 0.18, green: 0.18, blue: 0.20),
                    bottom: Color(red: 0.03, green: 0.03, blue: 0.04))
    ]

    private let accents: [(String, Color)] = [
        ("Pink", .pink), ("Purple", .purple), ("Blue", .blue), ("Cyan", .cyan),
        ("Green", .green), ("Orange", .orange), ("Red", .red)
    ]

    private let credits: [(String, String)] = [
        ("misaki", "lead larper"),
        ("Mr. Banana", "kernel whisperer"),
        ("my cat", "beta tester (walked on the keyboard)"),
        ("Stack Overflow", "literally everything"),
        ("a random guy on Discord", "moral support"),
        ("you 💜", "for believing")
    ]

    private var theme: MisakiTheme { themes[min(themeIndex, themes.count - 1)] }
    private var accent: Color { accents[min(accentIndex, accents.count - 1)].1 }
    private var logColor: Color { logUsesAccent ? accent : .green }

    private var steps: [(String, Double)] {
        [
            ("[*] misakilarp v1.0 starting...", 0.05),
            ("[*] device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)", 0.10),
            ("[*] using exploit: \(exploits[exploit])", 0.16),
            ("[*] kernel luck: \(Int(luck))%", 0.22),
            ("[*] fetching kernel offsets...", 0.30),
            ("[+] offsets found", 0.38),
            ("[*] triggering vulnerability...", 0.46),
            ("[*] racing threads...", 0.54),
            ("[+] got kernel read/write", 0.62),
            (disablePAC ? "[*] bypassing PAC..." : "[*] PAC bypass skipped", 0.70),
            ("[*] bypassing PPL...", 0.76),
            ("[+] escaping sandbox", 0.82),
            (summonCat ? "[+] kernel cat summoned 🐱" : "[*] remounting rootfs as r/w...", 0.88),
            ("[*] installing bootstrap...", 0.94),
            ("[+] jailbreak succeeded, respring to finish", 1.0)
        ]
    }

    private var buttonTitle: String {
        switch phase {
        case .idle: return "Jailbreak"
        case .running: return "Jailbreaking..."
        case .done: return "Respring"
        }
    }

    private var statusText: String {
        switch phase {
        case .idle: return "Ready"
        case .running: return logs.last ?? "Starting..."
        case .done: return "Jailbroken"
        }
    }

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.02, blue: 0.11, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            TabView {
                jailbreakTab
                    .tabItem { Label("jailbreak", systemImage: "lock.open.fill") }
                creditsTab
                    .tabItem { Label("credits", systemImage: "heart.fill") }
                exploitTab
                    .tabItem { Label("exploit", systemImage: "bolt.fill") }
                settingsTab
                    .tabItem { Label("settings", systemImage: "gearshape.fill") }
            }
            .accentColor(accent)

            if showLock {
                lockScreen
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }

            Color.black
                .ignoresSafeArea()
                .opacity(blackout ? 1 : 0)
                .allowsHitTesting(blackout)
                .zIndex(3)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(blackout)
        .alert("Are you sure u wanna jailbreak?💜💜", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Jailbreak", role: .destructive) {
                Task { await startJailbreak() }
            }
        } message: {
            Text("This will run the \(exploits[exploit]) exploit and install the bootstrap on your device. Keep misakilarp open until it finishes and don't lock your screen.")
        }
    }

    // MARK: - Shared pieces

    private var background: some View {
        LinearGradient(
            colors: [theme.top, theme.bottom],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 42, weight: .heavy, design: .rounded))
            .foregroundStyle(
                LinearGradient(colors: [accent, accent.opacity(0.55)],
                               startPoint: .leading, endPoint: .trailing)
            )
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent.opacity(0.25))
            .cornerRadius(10)
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard haptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    // MARK: - Jailbreak tab

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.7), radius: 10)
            VStack(spacing: 4) {
                Image(systemName: phase == .done ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 38))
                    .foregroundColor(accent)
                Text(phase == .idle ? "—" : "\(Int(progress * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 170, height: 170)
    }

    private var logBox: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs.indices, id: \.self) { i in
                        Text(logs[i])
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(logColor)
                            .id(i)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .onChange(of: logs.count) { count in
                withAnimation { proxy.scrollTo(count - 1, anchor: .bottom) }
            }
        }
        .frame(height: 170)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var mainButton: some View {
        Button {
            if phase == .idle {
                showConfirm = true
            } else if phase == .done {
                Task { await respring() }
            }
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(phase == .running ? Color.gray : accent)
                .cornerRadius(14)
        }
        .disabled(phase == .running)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private var jailbreakTab: some View {
        ZStack {
            background

            VStack(spacing: 16) {
                title("misakilarp")
                    .padding(.top, 30)

                Text("iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                progressRing
                    .padding(.top, 6)

                Text(statusText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    chip("exploit: \(exploits[exploit])")
                    chip("luck: \(Int(luck))%")
                }

                logBox

                Spacer()

                mainButton
            }
        }
    }

    // MARK: - Credits tab

    private var creditsTab: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 14) {
                    title("credits")
                        .padding(.top, 40)

                    Text("made possible by")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 8)

                    ForEach(credits.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(credits[i].0)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(credits[i].1)
                                .font(.system(size: 13))
                                .foregroundColor(accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Exploit tab

    private var exploitTab: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title("exploit")
                        .padding(.top, 40)

                    Picker("Exploit", selection: $exploit) {
                        ForEach(exploits.indices, id: \.self) { i in
                            Text(exploits[i]).tag(i)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kernel luck: \(Int(luck))%")
                            .foregroundColor(.white)
                        Slider(value: $luck, in: 0...100, step: 1)
                            .accentColor(accent)
                    }

                    Toggle("Disable PAC", isOn: $disablePAC)
                        .toggleStyle(SwitchToggleStyle(tint: accent))
                        .foregroundColor(.white)

                    Toggle("Summon kernel cat 🐱", isOn: $summonCat)
                        .toggleStyle(SwitchToggleStyle(tint: accent))
                        .foregroundColor(.white)

                    Button {
                        generateOffsets()
                    } label: {
                        Text("Calibrate offsets")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accent.opacity(0.85))
                            .cornerRadius(14)
                    }

                    if !offsets.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(offsets.indices, id: \.self) { i in
                                Text(offsets[i])
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(logColor)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Settings tab

    private func settingsCard<Content: View>(_ heading: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(heading)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.07))
        .cornerRadius(14)
    }

    private var accentPicker: some View {
        HStack(spacing: 12) {
            ForEach(accents.indices, id: \.self) { i in
                Circle()
                    .fill(accents[i].1)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: accentIndex == i ? 3 : 0)
                    )
                    .onTapGesture { accentIndex = i }
            }
        }
    }

    private var themePicker: some View {
        VStack(spacing: 10) {
            ForEach(themes.indices, id: \.self) { i in
                HStack {
                    LinearGradient(colors: [themes[i].top, themes[i].bottom],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(width: 44, height: 28)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    Text(themes[i].name)
                        .foregroundColor(.white)
                    Spacer()
                    if themeIndex == i {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { themeIndex = i }
            }
        }
    }

    private var settingsTab: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title("settings")
                        .padding(.top, 40)

                    settingsCard("Accent color") {
                        accentPicker
                    }

                    settingsCard("Theme") {
                        themePicker
                    }

                    settingsCard("Respring") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Duration: \(Int(respringSeconds)) s")
                                .foregroundColor(.white)
                            Slider(value: $respringSeconds, in: 3...15, step: 1)
                                .accentColor(accent)
                        }
                        Toggle("Show lock screen after", isOn: $lockAfterRespring)
                            .toggleStyle(SwitchToggleStyle(tint: accent))
                            .foregroundColor(.white)
                    }

                    settingsCard("General") {
                        Toggle("Haptics", isOn: $haptics)
                            .toggleStyle(SwitchToggleStyle(tint: accent))
                            .foregroundColor(.white)
                        Toggle("Logs use accent color", isOn: $logUsesAccent)
                            .toggleStyle(SwitchToggleStyle(tint: accent))
                            .foregroundColor(.white)
                    }

                    Button {
                        themeIndex = 0
                        accentIndex = 0
                        respringSeconds = 6
                        haptics = true
                        lockAfterRespring = true
                        logUsesAccent = false
                    } label: {
                        Text("Reset settings")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(14)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Lock screen (shown after respring)

    private var lockScreen: some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.75), theme.top, theme.bottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 60)

                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text(Date(), style: .time)
                    .font(.system(size: 88, weight: .thin, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text("Swipe up to unlock")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))

                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 140, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { unlock() }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height < -60 { unlock() }
            }
        )
    }

    private func unlock() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            showLock = false
        }
    }

    // MARK: - Logic

    private func generateOffsets() {
        let names = ["kernel_base", "proc_ro", "vm_map", "pmap_enter", "larp_ptr", "banana_slide"]
        offsets = names.map { name in
            let value = String(UInt32.random(in: 0x10000000...0xFFFFFFFF), radix: 16)
            return "\(name) = 0xfffffff0\(value)"
        }
    }

    @MainActor
    private func startJailbreak() async {
        guard phase == .idle else { return }
        phase = .running
        logs = []
        progress = 0
        for (line, value) in steps {
            logs.append(line)
            withAnimation(.easeInOut(duration: 0.4)) { progress = value }
            try? await Task.sleep(nanoseconds: UInt64.random(in: 350_000_000...900_000_000))
        }
        phase = .done
        haptic(.success)
    }

    @MainActor
    private func respring() async {
        withAnimation(.easeIn(duration: 0.3)) { blackout = true }
        try? await Task.sleep(nanoseconds: UInt64(respringSeconds * 1_000_000_000))
        phase = .idle
        progress = 0
        logs = []
        withAnimation(.easeOut(duration: 0.6)) {
            showLock = lockAfterRespring
            blackout = false
        }
        haptic(.success)
    }
}
