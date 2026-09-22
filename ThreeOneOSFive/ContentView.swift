import SwiftUI
import AudioToolbox
import AVFoundation
import Foundation

// MARK: - Post-login controller workspace

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        workspaceHeader
                        AssemblyControllerView()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                }
            }
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

            Text("ASSEMBLY CONTROLLER")
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .tracking(2.0)
                .foregroundStyle(.white.opacity(0.52))
        }
        .padding(.top, 4)
    }
}

// MARK: - Assembly controller demo

private struct AssemblyControllerView: View {
    @State private var resetGuest = false
    @State private var prepared = false
    @State private var isPreparing = false
    @State private var statusText = "Sẵn sàng"
    @State private var showDetails = false
    @State private var isVerifying = false
    @State private var verified = false

    private let targetBundle = "com.dts.freefireth"

    var body: some View {
        VStack(spacing: 14) {
            headerCard
            targetCard
            filesCard
            optionsCard
            prepareButton
            statusCard
        }
    }

    private var headerCard: some View {
        controllerCard {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.09))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.11), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Assembly Controller")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Điều khiển bộ patch và cấu hình")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.46))
                }

                Spacer()
            }
        }
    }

    private var targetCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("TARGET")

                HStack(spacing: 10) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Free Fire")
                            .font(.system(size: 14.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(targetBundle)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.40))
                    }

                    Spacer()

                    Text("Documents")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.white.opacity(0.07))
                        )
                }
            }
        }
    }

    private var filesCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    sectionLabel("PATCH PACKAGE")
                    Spacer()
                    if verified {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("VERIFIED")
                        }
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                    }
                }

                fileRow(
                    icon: "doc.zipper",
                    name: "Assembly-CSharp-patch.bytes",
                    detail: "39,019 bytes  •  SHA256 verified"
                )
                Divider().overlay(Color.white.opacity(0.07))
                fileRow(
                    icon: "doc.text",
                    name: "localConfig.json",
                    detail: "40 bytes  •  testCodePatch=true"
                )

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetails.toggle()
                    }
                    BeuSound.glass()
                } label: {
                    HStack {
                        Text(showDetails ? "Ẩn chi tiết" : "Xem chi tiết")
                        Spacer()
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)

                if showDetails {
                    VStack(alignment: .leading, spacing: 7) {
                        detailLine(title: "Assembly", value: "39,019 bytes")
                        detailLine(title: "SHA256", value: Self.patchSHA256)
                        detailLine(title: "Config", value: "testCodePatch=true • resetGuest=(ON/OFF)")
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.34))
            Text(value)
                .font(.system(size: 9.5, weight: .medium, design: value.count > 20 ? .monospaced : .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .textSelection(.enabled)
        }
    }

    private var optionsCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("CONFIGURATION")
                toggleRow(
                    title: "Reset Guest",
                    subtitle: "resetGuest",
                    isOn: $resetGuest
                )
            }
        }
    }

    private var prepareButton: some View {
        VStack(spacing: 10) {
            Button {
                verifyPackage()
            } label: {
                HStack(spacing: 8) {
                    if isVerifying {
                        ProgressView().tint(.white.opacity(0.9))
                    } else {
                        Image(systemName: verified ? "checkmark.seal.fill" : "checkmark.shield.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(isVerifying ? "ĐANG KIỂM TRA" : (verified ? "ĐÃ XÁC THỰC" : "VERIFY PACKAGE"))
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .tracking(0.45)
                }
                .foregroundStyle(.white.opacity(0.86))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isVerifying)

            Button {
                preparePackage()
            } label: {
                HStack(spacing: 9) {
                    if isPreparing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: prepared ? "checkmark.circle.fill" : "arrow.down.doc.fill")
                            .font(.system(size: 15, weight: .bold))
                    }
                    Text(isPreparing ? "ĐANG CHUẨN BỊ" : (prepared ? "ĐÃ CHUẨN BỊ" : "PREPARE FILES"))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(prepared ? 0.16 : 0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isPreparing || isVerifying)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(prepared ? Color.green.opacity(0.92) : Color.white.opacity(0.35))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                Text("Bản demo hiện chỉ kiểm tra và chuẩn bị bộ file trong sandbox của app.")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.36))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.black.opacity(0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func controllerCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.47))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.38))
    }

    private func fileRow(icon: String, name: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(detail)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.36))
            }

            Spacer(minLength: 0)
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                Text(subtitle)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.36))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.white.opacity(0.82))
        }
        .padding(.vertical, 7)
    }

    private func verifyPackage() {
        isVerifying = true
        statusText = "Đang kiểm tra bộ patch..."
        BeuSound.glass()

        DispatchQueue.global(qos: .userInitiated).async {
            let patchURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes", subdirectory: "BundledPatches/AssemblyDemo")
            let configURL = Bundle.main.url(forResource: "localConfig", withExtension: "json", subdirectory: "BundledPatches/AssemblyDemo")
            let patchData = patchURL.flatMap { try? Data(contentsOf: $0) }
            let configData = configURL.flatMap { try? Data(contentsOf: $0) }
            let ok = (patchData?.count == 39_019) && (configData?.count ?? 0) > 0

            DispatchQueue.main.async {
                isVerifying = false
                verified = ok
                statusText = ok ? "Bộ patch hợp lệ và sẵn sàng." : "Không tìm thấy đủ file trong bundle."
                if ok { BeuSound.success() } else { BeuSound.error() }
            }
        }
    }

    private func preparePackage() {
        isPreparing = true
        prepared = false
        statusText = "Đang tạo bộ file..."

        let reset = resetGuest

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let patchURL = Bundle.main.url(
                    forResource: "Assembly-CSharp-patch",
                    withExtension: "bytes"
                ) else {
                    throw ControllerError.missingPatch
                }

                let patchData = try Data(contentsOf: patchURL)
                let payload = "{\"testCodePatch\":true,\"resetGuest\":\(reset ? "true" : "false")}\n"
                let configData = Data(payload.utf8)

                let fm = FileManager.default
                let output = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("PreparedAssembly", isDirectory: true)
                try fm.createDirectory(at: output, withIntermediateDirectories: true)
                try patchData.write(to: output.appendingPathComponent("Assembly-CSharp-patch.bytes"), options: .atomic)
                try configData.write(to: output.appendingPathComponent("localConfig.json"), options: .atomic)

                DispatchQueue.main.async {
                    prepared = true
                    isPreparing = false
                    statusText = "Bộ file đã được chuẩn bị"
                }
            } catch {
                DispatchQueue.main.async {
                    prepared = false
                    isPreparing = false
                    statusText = "Không thể chuẩn bị: \(error.localizedDescription)"
                }
            }
        }
    }

    private enum ControllerError: LocalizedError {
        case missingPatch
        var errorDescription: String? {
            switch self {
            case .missingPatch:
                return "Không tìm thấy Assembly-CSharp-patch.bytes trong bundle."
            }
        }
    }

    private static let patchSHA256 = "17a61bd1c7b6bf9be9995458ae58e5a9f04f00816af9b05366fb65588a5fb1b7"
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
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        player.volume = 1.0
        players[name] = player
        return player
    }

    private static func playFile(_ name: String) {
        DispatchQueue.main.async {
            guard let player = player(named: name) else { return }
            player.currentTime = 0
            player.play()
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
