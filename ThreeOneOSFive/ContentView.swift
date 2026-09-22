import SwiftUI
import AudioToolbox
import AVFoundation

// MARK: - Post-login root
//
// The old Home / Settings / account / side-menu UI has been intentionally
// removed. The license gate remains unchanged in App.swift / LicenseGateView.
// This view is now a clean shell for the new controller workspace.

struct ContentView: View {
    var body: some View {
        ZStack {
            // AppVideoBackground is owned by App.swift and remains untouched.
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                workspaceHeader

                workspaceCard
                    .padding(.top, 22)
                    .padding(.horizontal, 20)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
    }

    private var workspaceHeader: some View {
        VStack(spacing: 7) {
            Text("BEU")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(.white)

            Text("NEW WORKSPACE")
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .tracking(2.0)
                .foregroundStyle(.white.opacity(0.52))
        }
        .padding(.top, 8)
    }

    private var workspaceCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 11) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.white.opacity(0.09))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Assembly Controller")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Workspace mới sẵn sàng để triển khai")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer(minLength: 0)
            }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    VStack(spacing: 7) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))

                        Text("Khu vực mới")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.86))

                        Text("Các chức năng cũ đã được gỡ khỏi màn hình sau đăng nhập.")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 20)
                    }
                )
                .frame(height: 190)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.46))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}


// MARK: - System UI sounds

enum BeuSound {
    private static var players: [String: AVAudioPlayer] = [:]
    private static var sessionReady = false

    private static func ensureSession() {
        guard !sessionReady else { return }
        sessionReady = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
    }

    private static func player(named name: String) -> AVAudioPlayer? {
        ensureSession()
        if let existing = players[name] {
            return existing
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav")
                ?? Bundle.main.url(forResource: name, withExtension: "caf") else {
            return nil
        }
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.prepareToPlay()
        p.volume = 1.0
        players[name] = p
        return p
    }

    private static func playFile(_ name: String) {
        DispatchQueue.main.async {
            guard let p = player(named: name) else { return }
            p.currentTime = 0
            p.play()
        }
    }

    static func glass() { playFile("ui_click") }
    static func soft() { playFile("ui_unclick") }
    static func tick() { playFile("ui_double") }
    static func toggle() { playFile("ui_unclick") }

    static func success() {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1111)
        }
    }

    static func error() {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1073)
        }
    }

    static func click() { glass() }
}
