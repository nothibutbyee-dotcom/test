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

struct MisakiView: View {
    enum Phase { case idle, running, done }

    // Jailbreak tab
    @State private var phase: Phase = .idle
    @State private var progress: Double = 0
    @State private var logs: [String] = []
    @State private var blackout = false
    @State private var showConfirm = false

    // Exploit tab
    @State private var exploit = 0
    @State private var luck: Double = 50
    @State private var disablePAC = true
    @State private var summonCat = false
    @State private var offsets: [String] = []

    private let exploits = ["kfd", "landa", "misakipwn"]

    private let credits: [(String, String)] = [
        ("misaki", "lead larper"),
        ("Mr. Banana", "kernel whisperer"),
        ("my cat", "beta tester (walked on the keyboard)"),
        ("Stack Overflow", "literally everything"),
        ("a random guy on Discord", "moral support"),
        ("you 💜", "for believing")
    ]

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

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.02, blue: 0.11, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            TabView {
                jailbreakTab
                    .tabItem { Label("jailbreak", systemImage: "lock.open.fill") }
                creditsTab
                    .tabItem { Label("credits", systemImage: "heart.fill") }
                exploitTab
                    .tabItem { Label("exploit", systemImage: "bolt.fill") }
            }
            .accentColor(.pink)

            Color.black
                .ignoresSafeArea()
                .opacity(blackout ? 1 : 0)
                .allowsHitTesting(blackout)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(blackout)
        .alert("Are you sure u wanna jailbreak?💜💜", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Jailbreak") {
                Task { await startJailbreak() }
            }
        }
    }

    // MARK: - Shared pieces

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.12, green: 0.04, blue: 0.20),
                     Color(red: 0.02, green: 0.02, blue: 0.06)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 42, weight: .heavy, design: .rounded))
            .foregroundStyle(
                LinearGradient(colors: [.pink, .purple],
                               startPoint: .leading, endPoint: .trailing)
            )
    }

    // MARK: - Jailbreak tab

    private var jailbreakTab: some View {
        ZStack {
            background

            VStack(spacing: 18) {
                title("misakilarp")
                    .padding(.top, 40)

                Text("iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                if phase != .idle {
                    ProgressView(value: progress)
                        .tint(.pink)
                        .padding(.horizontal)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(logs.indices, id: \.self) { i in
                                Text(logs[i])
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.green)
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
                .frame(height: 280)
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

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
                        .background(phase == .running ? Color.gray : Color.pink)
                        .cornerRadius(14)
                }
                .disabled(phase == .running)
                .padding(.horizontal)
                .padding(.bottom, 16)
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
                                .foregroundColor(.pink.opacity(0.9))
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
                            .accentColor(.pink)
                    }

                    Toggle("Disable PAC", isOn: $disablePAC)
                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                        .foregroundColor(.white)

                    Toggle("Summon kernel cat 🐱", isOn: $summonCat)
                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                        .foregroundColor(.white)

                    Button {
                        generateOffsets()
                    } label: {
                        Text("Calibrate offsets")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.purple)
                            .cornerRadius(14)
                    }

                    if !offsets.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(offsets.indices, id: \.self) { i in
                                Text(offsets[i])
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.green)
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
    }

    @MainActor
    private func respring() async {
        withAnimation(.easeIn(duration: 0.3)) { blackout = true }
        try? await Task.sleep(nanoseconds: 6_000_000_000)
        phase = .idle
        progress = 0
        logs = []
        withAnimation(.easeOut(duration: 0.5)) { blackout = false }
    }
}
