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

    @State private var phase: Phase = .idle
    @State private var progress: Double = 0
    @State private var logs: [String] = []
    @State private var blackout = false

    private let steps: [(String, Double)] = [
        ("[*] misakilarp v1.0 starting...", 0.05),
        ("[*] checking device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)", 0.10),
        ("[*] fetching kernel offsets...", 0.18),
        ("[+] offsets found (trust me)", 0.25),
        ("[*] triggering vulnerability...", 0.34),
        ("[*] racing threads...", 0.42),
        ("[+] got kernel read/write", 0.52),
        ("[*] bypassing PAC...", 0.60),
        ("[*] bypassing PPL...", 0.68),
        ("[+] escaping sandbox", 0.76),
        ("[*] remounting rootfs as r/w...", 0.83),
        ("[*] installing bootstrap...", 0.90),
        ("[*] loading tweak injection...", 0.96),
        ("[+] done. nothing was actually modified.", 1.0)
    ]

    private var buttonTitle: String {
        switch phase {
        case .idle: return "Jailbreak"
        case .running: return "Jailbreaking..."
        case .done: return "Respring"
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.04, blue: 0.20),
                         Color(red: 0.02, green: 0.02, blue: 0.06)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("misakilarp")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.pink, .purple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
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
                    Task {
                        if phase == .idle { await startJailbreak() }
                        else if phase == .done { await fakeRespring() }
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

                Text("Fake jailbreak, made for fun. Does nothing.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 12)
            }

            Color.black
                .ignoresSafeArea()
                .overlay(ProgressView().tint(.white))
                .opacity(blackout ? 1 : 0)
                .allowsHitTesting(blackout)
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
    private func fakeRespring() async {
        withAnimation(.easeIn(duration: 0.3)) { blackout = true }
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        phase = .idle
        progress = 0
        logs = []
        withAnimation(.easeOut(duration: 0.5)) { blackout = false }
    }
}
