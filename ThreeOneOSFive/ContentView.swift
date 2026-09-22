import SwiftUI
import UIKit
import AudioToolbox
import AVFoundation
import Foundation
import CryptoKit

// MARK: - Post-login controller workspace

struct ContentView: View {
    var body: some View {
        ZStack {
            // Livebg.mp4 is provided globally by App.swift.
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        workspaceHeader
                        AssemblyControllerView()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 26)
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

// MARK: - Controller

private struct AssemblyControllerView: View {
    @AppStorage("assembly.resetGuest") private var resetGuest = false
    @State private var packageState: PackageState = .checking
    @State private var packageInfo = PackageInfo.empty
    @State private var prepared = false
    @State private var preparing = false
    @State private var exporting = false
    @State private var exportURL: URL?
    @State private var statusText = "Đang kiểm tra bộ file..."
    @State private var showDetails = false

    private let targetBundle = "com.dts.freefireth"
    private let expectedPatchSize = 39_019
    private let expectedPatchSHA256 = "17a61bd1c7b6bf9be9995458ae58e5a9f04f00816af9b05366fb65588a5fb1b7"

    var body: some View {
        VStack(spacing: 14) {
            overviewCard
            targetCard
            packageCard
            configurationCard
            actionsCard
            statusCard
        }
        .onAppear {
            loadPackageInfo()
        }
        .sheet(isPresented: Binding(
            get: { exportURL != nil },
            set: { presented in
                if !presented { exportURL = nil }
            }
        )) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: Overview

    private var overviewCard: some View {
        controllerCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Assembly Controller")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Quản lý bộ patch và cấu hình")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.46))
                }

                Spacer()

                stateBadge
            }
        }
    }

    private var stateBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(packageState == .ready ? Color.green.opacity(0.9) : Color.white.opacity(0.35))
                .frame(width: 6, height: 6)

            Text(packageState == .ready ? "READY" : "CHECKING")
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.5)
        }
        .foregroundStyle(.white.opacity(0.56))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    // MARK: Target

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
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("Documents")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.07)))
                }
            }
        }
    }

    // MARK: Package

    private var packageCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    sectionLabel("PATCH PACKAGE")
                    Spacer()

                    if packageState == .ready {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("VERIFIED")
                        }
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                    }
                }

                packageRow(
                    icon: "doc.zipper",
                    title: "Assembly-CSharp-patch.bytes",
                    detail: packageInfo.patchDetail
                )

                Divider()
                    .overlay(Color.white.opacity(0.07))

                packageRow(
                    icon: "doc.text",
                    title: "localConfig.json",
                    detail: "testCodePatch=true • resetGuest=(ON/OFF)"
                )

                Button {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        showDetails.toggle()
                    }
                    BeuSound.soft()
                } label: {
                    HStack(spacing: 6) {
                        Text(showDetails ? "Ẩn chi tiết" : "Xem chi tiết")
                        Spacer()
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
                }
                .buttonStyle(.plain)

                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        detailLine(title: "PATCH SIZE", value: "\(packageInfo.patchBytes.formatted()) bytes")
                        detailLine(title: "PATCH SHA256", value: packageInfo.patchSHA256.isEmpty ? "—" : packageInfo.patchSHA256)
                        detailLine(title: "CONFIG OUTPUT", value: configPreview)
                    }
                    .padding(.top, 1)
                }
            }
        }
    }

    private func packageRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.06)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(detail)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.35)
                .foregroundStyle(.white.opacity(0.30))

            Text(value)
                .font(.system(size: 9.5, weight: .medium, design: value.count > 28 ? .monospaced : .rounded))
                .foregroundStyle(.white.opacity(0.60))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .textSelection(.enabled)
        }
    }

    // MARK: Configuration

    private var configurationCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    sectionLabel("CONFIGURATION")
                    Spacer()
                    Text("testCodePatch = true")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                }

                toggleRow(
                    title: "Reset Guest",
                    subtitle: resetGuest ? "resetGuest = true" : "resetGuest = false",
                    isOn: $resetGuest
                )
            }
        }
    }

    // MARK: Actions

    private var actionsCard: some View {
        VStack(spacing: 10) {
            Button {
                preparePackage()
            } label: {
                HStack(spacing: 9) {
                    if preparing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: prepared ? "checkmark.circle.fill" : "arrow.down.doc.fill")
                            .font(.system(size: 15, weight: .bold))
                    }

                    Text(preparing ? "ĐANG CHUẨN BỊ" : (prepared ? "ĐÃ CHUẨN BỊ" : "PREPARE FILES"))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(prepared ? 0.14 : 0.11))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(preparing || packageState != .ready)

            Button {
                exportPackage()
            } label: {
                HStack(spacing: 8) {
                    if exporting {
                        ProgressView()
                            .tint(.white.opacity(0.86))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .bold))
                    }

                    Text(exporting ? "ĐANG TẠO GÓI" : "EXPORT PACKAGE")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .tracking(0.45)
                }
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(exporting || packageState != .ready)
        }
    }

    private var configPreview: String {
        "{\"testCodePatch\":true,\"resetGuest\":\(resetGuest ? "true" : "false")}"
    }

    // MARK: Status

    private var statusCard: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(statusColor.opacity(0.92))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))

                Text("Bộ file được chuẩn bị trong sandbox của app.")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.34))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.black.opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch packageState {
        case .checking:
            return .white
        case .ready:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    // MARK: Package operations

    private func loadPackageInfo() {
        packageState = .checking
        statusText = "Đang kiểm tra bộ file..."

        DispatchQueue.global(qos: .userInitiated).async {
            let patchURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes")
            let configURL = Bundle.main.url(forResource: "localConfig", withExtension: "json")

            guard let patchURL, let configURL,
                  let patchData = try? Data(contentsOf: patchURL),
                  let configData = try? Data(contentsOf: configURL) else {
                DispatchQueue.main.async {
                    packageInfo = .empty
                    packageState = .failed
                    statusText = "Thiếu file trong bundle."
                }
                return
            }

            let hash = SHA256.hash(data: patchData)
                .map { String(format: "%02x", $0) }
                .joined()

            let ok = patchData.count == expectedPatchSize && hash == expectedPatchSHA256 && !configData.isEmpty

            let info = PackageInfo(
                patchBytes: patchData.count,
                patchSHA256: hash,
                patchDetail: "\(patchData.count.formatted()) bytes  •  SHA256 \(Self.shortHash(hash))"
            )

            DispatchQueue.main.async {
                packageInfo = info
                packageState = ok ? .ready : .failed
                statusText = ok ? "Bộ patch đã sẵn sàng." : "Bộ patch không khớp bản đã đăng ký."
            }
        }
    }

    private func preparePackage() {
        guard packageState == .ready else { return }

        preparing = true
        prepared = false
        statusText = "Đang chuẩn bị bộ file..."
        BeuSound.glass()

        let reset = resetGuest
        let config = "{\"testCodePatch\":true,\"resetGuest\":\(reset ? "true" : "false")}\n"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let patchURL = Bundle.main.url(
                    forResource: "Assembly-CSharp-patch",
                    withExtension: "bytes"
                ) else {
                    throw ControllerError.missingPatch
                }

                let patchData = try Data(contentsOf: patchURL)
                let fileManager = FileManager.default
                let root = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let output = root.appendingPathComponent("PreparedAssembly", isDirectory: true)

                try fileManager.createDirectory(at: output, withIntermediateDirectories: true)

                try patchData.write(
                    to: output.appendingPathComponent("Assembly-CSharp-patch.bytes"),
                    options: .atomic
                )

                try Data(config.utf8).write(
                    to: output.appendingPathComponent("localConfig.json"),
                    options: .atomic
                )

                DispatchQueue.main.async {
                    prepared = true
                    preparing = false
                    statusText = "Bộ file đã được chuẩn bị."
                    BeuSound.success()
                }
            } catch {
                DispatchQueue.main.async {
                    preparing = false
                    prepared = false
                    packageState = .failed
                    statusText = "Chuẩn bị thất bại: \(error.localizedDescription)"
                    BeuSound.error()
                }
            }
        }
    }

    private func exportPackage() {
        guard packageState == .ready else { return }

        exporting = true
        statusText = "Đang tạo gói ZIP..."
        BeuSound.soft()

        let reset = resetGuest
        let config = "{\"testCodePatch\":true,\"resetGuest\":\(reset ? "true" : "false")}\n"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let patchURL = Bundle.main.url(
                    forResource: "Assembly-CSharp-patch",
                    withExtension: "bytes"
                ) else {
                    throw ControllerError.missingPatch
                }

                let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let work = root.appendingPathComponent("ExportedAssembly", isDirectory: true)
                try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)

                let patchCopy = work.appendingPathComponent("Assembly-CSharp-patch.bytes")
                let configURL = work.appendingPathComponent("localConfig.json")
                let zipURL = root.appendingPathComponent("BEU-Assembly-Package.zip")

                try? FileManager.default.removeItem(at: zipURL)

                if FileManager.default.fileExists(atPath: patchCopy.path) {
                    try FileManager.default.removeItem(at: patchCopy)
                }
                if FileManager.default.fileExists(atPath: configURL.path) {
                    try FileManager.default.removeItem(at: configURL)
                }

                try FileManager.default.copyItem(at: patchURL, to: patchCopy)
                try Data(config.utf8).write(to: configURL, options: .atomic)

                _ = try ZIPArchiveWriter.write(
                    items: [patchCopy, configURL],
                    to: zipURL
                )

                DispatchQueue.main.async {
                    exporting = false
                    exportURL = zipURL
                    statusText = "Đã tạo gói ZIP."
                    BeuSound.success()
                }
            } catch {
                DispatchQueue.main.async {
                    exporting = false
                    statusText = "Xuất gói thất bại: \(error.localizedDescription)"
                    BeuSound.error()
                }
            }
        }
    }

    private func controllerCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(Color.black.opacity(0.44))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(Color.white.opacity(0.095), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .tracking(0.75)
            .foregroundStyle(.white.opacity(0.32))
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))

                Text(subtitle)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.white.opacity(0.82))
                .scaleEffect(0.9)
        }
        .padding(.vertical, 8)
    }

    private static func shortHash(_ hash: String) -> String {
        guard hash.count >= 12 else { return hash }
        return String(hash.prefix(8)) + "…" + String(hash.suffix(4))
    }

    private struct PackageInfo {
        let patchBytes: Int
        let patchSHA256: String
        let patchDetail: String

        static let empty = PackageInfo(
            patchBytes: 0,
            patchSHA256: "",
            patchDetail: "Chưa kiểm tra"
        )
    }

    private enum PackageState {
        case checking, ready, failed
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
}

// MARK: - Share sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }

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
