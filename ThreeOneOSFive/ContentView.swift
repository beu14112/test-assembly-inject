import SwiftUI
import UIKit
import AudioToolbox
import AVFoundation
import Foundation
import CryptoKit

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.30)
                .ignoresSafeArea()

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

private struct AssemblyControllerView: View {
    // Persist controller selections so the control panel can be reopened without losing state.
    @AppStorage("assembly.resetGuest") private var resetGuest = false

    @AppStorage("assembly.feature.aimBot") private var aimBot = false
    @AppStorage("assembly.feature.aimSilent") private var aimSilent = false
    @AppStorage("assembly.feature.aimMode") private var aimMode = 0

    @AppStorage("assembly.feature.espLine") private var espLine = false
    @AppStorage("assembly.feature.espBox") private var espBox = false
    @AppStorage("assembly.feature.healthBar") private var healthBar = false
    @AppStorage("assembly.feature.espDistance") private var espDistance = false
    @AppStorage("assembly.feature.espName") private var espName = false

    @AppStorage("assembly.feature.noRecoil") private var noRecoil = false
    @AppStorage("assembly.feature.runSpeed") private var runSpeed = false
    @AppStorage("assembly.feature.skySpeed") private var skySpeed = false
    @AppStorage("assembly.feature.healFast") private var healFast = false

    @State private var packageState: PackageState = .checking
    @State private var packageInfo = PackageInfo.empty
    @EnvironmentObject private var appState: AppState
    @State private var injected = false
    @State private var injecting = false
    @State private var statusText = "Đang kiểm tra bộ file..."
    @State private var liveSyncWorkItem: DispatchWorkItem?
    @State private var showDetails = false

    private let targetBundle = "com.dts.freefireth"
    private let expectedPatchSize = 39_019
    private let expectedPatchSHA256 = "17a61bd1c7b6bf9be9995458ae58e5a9f04f00816af9b05366fb65588a5fb1b7"

    private let pinkAccent = Color(red: 1.0, green: 0.7216, blue: 0.7765)

    var body: some View {
        VStack(spacing: 14) {
            overviewCard
            targetCard
            packageCard
            featureCard
            configurationCard
            actionsCard
            statusCard
        }
        .onAppear { loadPackageInfo() }
            }

    private var overviewCard: some View {
        controllerCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Assembly Controller")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Điều khiển trạng thái của patch thật")
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
                    Text("Assembly patch")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.07)))
                }
            }
        }
    }

    private var packageCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    sectionLabel("PATCH PACKAGE")
                    Spacer()
                    if packageState == .ready {
                        Label("VERIFIED", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }

                packageRow(
                    icon: "doc.zipper",
                    title: "Assembly-CSharp-patch.bytes",
                    detail: packageInfo.patchDetail
                )

                Divider().overlay(Color.white.opacity(0.07))

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
                        detailLine(title: "SOURCE SHA256", value: packageInfo.patchSHA256.isEmpty ? "—" : packageInfo.patchSHA256)
                        detailLine(title: "PATCH AFTER INJECT", value: packageInfo.configuredSHA256.isEmpty ? "—" : packageInfo.configuredSHA256)
                    }
                    .padding(.top, 1)
                }
            }
        }
    }

    private var featureCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionLabel("ASSEMBLY FEATURES")
                    Spacer()
                    Text("SOURCE: .bytes")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.26))
                }

                Text("Các nút dưới đây map vào đúng state đã xác nhận trong patch.")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))

                VStack(spacing: 0) {
                    featureSectionTitle("AIM")
                    toggleRow(title: "Aim Bot", subtitle: "Bit 8192 trong dlt_st", isOn: liveBinding($aimBot))
                    toggleRow(title: "Aim Silent", subtitle: "Player.__silentOn", isOn: liveBinding($aimSilent))

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Chế Độ Aim")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.90))
                            Text(aimModeTitle)
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.38))
                        }
                        Spacer()
                        Picker("Aim Mode", selection: $aimMode) {
                            Text("Cổ").tag(0)
                            Text("Đầu").tag(1)
                            Text("Bụng").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 180)
                        .onChange(of: aimMode) { _ in
                            scheduleLiveSync()
                            BeuSound.toggle()
                        }
                    }
                    .padding(.vertical, 8)

                    featureSectionTitle("ESP")
                    toggleRow(title: "ESP Line", subtitle: "Bit 2 trong dlt_st", isOn: liveBinding($espLine))
                    toggleRow(title: "ESP Box", subtitle: "Bit 1 trong dlt_st", isOn: liveBinding($espBox))
                    toggleRow(title: "Health Bar", subtitle: "Bit 512 trong dlt_st", isOn: liveBinding($healthBar))
                    toggleRow(title: "ESP Distance", subtitle: "Bit 32768 trong dlt_st", isOn: liveBinding($espDistance))
                    toggleRow(title: "ESP Name", subtitle: "Player.__espName", isOn: liveBinding($espName))

                    featureSectionTitle("SPEED / COMBAT")
                    toggleRow(title: "No Recoil", subtitle: "Bit 1024 + __nrUser", isOn: liveBinding($noRecoil))
                    toggleRow(title: "Run Speed", subtitle: "Bit 16384 → __speedMul", isOn: liveBinding($runSpeed))
                    toggleRow(title: "Sky Speed", subtitle: "Bit 65536 → __skyMul", isOn: liveBinding($skySpeed))
                    toggleRow(title: "Heal Fast", subtitle: "Bit 131072 → __healMul", isOn: liveBinding($healFast))
                }
            }
        }
    }

    private var configurationCard: some View {
        controllerCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("CONFIGURATION")
                toggleRow(
                    title: "Reset Guest",
                    subtitle: "localConfig.json • mặc định OFF",
                    isOn: resetBinding($resetGuest)
                )
                Text("testCodePatch luôn được giữ TRUE và không hiển thị thành toggle.")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
    }

    private var actionsCard: some View {
        controllerCard {
            VStack(spacing: 10) {
                Button(action: injectPackage) {
                    actionLabel(
                        title: injecting ? "INJECTING..." : "INJECT",
                        icon: injecting ? "arrow.triangle.2.circlepath" : "bolt.fill"
                    )
                }
                .disabled(injecting || packageState != .ready)

                if !injected && !appState.exploitStatus.isSuccess {
                    Text("INJECT sẽ kiểm tra quyền truy cập target khi thực thi.")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                } else if injected {
                    Text("INJECTED • realtime state đang được đồng bộ.")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(pinkAccent.opacity(0.92))
                }
            }
        }
    }

    private func actionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .font(.system(size: 11.5, weight: .bold, design: .rounded))
        .tracking(0.55)
        .foregroundStyle(.black)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(pinkAccent)
        )
    }

    private var statusCard: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                Text(statusText)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineLimit(3)
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

    private var statusTitle: String {
        switch packageState {
        case .checking: return "CHECKING"
        case .ready: return injected ? "INJECTED" : "READY"
        case .failed: return "ERROR"
        }
    }

    private var statusIcon: String {
        switch packageState {
        case .checking: return "hourglass"
        case .ready: return injected ? "checkmark.circle.fill" : "checkmark.seal.fill"
        case .failed: return "xmark.octagon.fill"
        }
    }

    private var statusColor: Color {
        switch packageState {
        case .checking: return .white.opacity(0.65)
        case .ready: return injected ? pinkAccent : .green
        case .failed: return .red
        }
    }

    private var aimModeTitle: String {
        switch aimMode {
        case 0: return "Cổ"
        case 1: return "Đầu"
        default: return "Bụng"
        }
    }

    private var configPreview: String {
        "Reset Guest: \(resetGuest ? "ON" : "OFF") • testCodePatch: TRUE"
    }

    private func loadPackageInfo() {
        packageState = .checking
        statusText = "Đang kiểm tra bộ file..."
        injected = false

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let patchURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes"),
                      let configURL = Bundle.main.url(forResource: "localConfig", withExtension: "json") else {
                    throw ControllerError.missingPatch
                }

                let patchData = try Data(contentsOf: patchURL)
                let configData = try Data(contentsOf: configURL)
                let hash = Self.sha256(patchData)
                let ok = patchData.count == expectedPatchSize
                    && hash == expectedPatchSHA256
                    && !configData.isEmpty

                let installed = Self.targetHasLiveResources(targetBundle: targetBundle)

                DispatchQueue.main.async {
                    packageInfo = PackageInfo(
                        patchBytes: patchData.count,
                        patchSHA256: hash,
                        configuredSHA256: "",
                        patchDetail: "\(patchData.count.formatted()) bytes  •  SHA256 \(Self.shortHash(hash))"
                    )
                    packageState = ok ? .ready : .failed
                    injected = installed
                    statusText = ok
                        ? (installed ? "Bản gốc hợp lệ • target đã có resource live." : "Bản gốc khớp hash/size đã đăng ký.")
                        : "Bản gốc không khớp hash/size đã đăng ký."
                }
            } catch {
                DispatchQueue.main.async {
                    packageInfo = .empty
                    packageState = .failed
                    statusText = error.localizedDescription
                }
            }
        }
    }

    private func verifyTargetInstallation() {
        let installed = Self.targetHasLiveResources(targetBundle: targetBundle)
        injected = installed
        if installed {
            statusText = "Target đã có patch/config/state đang được controller quản lý."
        }
    }

    private static func targetHasLiveResources(targetBundle: String) -> Bool {
        guard let rootPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle),
              ContainerStore.isApplicationContainerPath(rootPath) else {
            return false
        }

        let documents = URL(fileURLWithPath: rootPath, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
        let patch = documents.appendingPathComponent("Assembly-CSharp-patch.bytes")
        let config = documents.appendingPathComponent("localConfig.json")
        let state = documents.appendingPathComponent("BEUControllerState.json")
        return FileManager.default.fileExists(atPath: patch.path)
            && FileManager.default.fileExists(atPath: config.path)
            && FileManager.default.fileExists(atPath: state.path)
    }

    private func injectPackage() {
        guard packageState == .ready, !injecting else { return }

        injecting = true
        injected = false
        statusText = "Đang cấu hình patch + ghi đè/thêm resource vào target..."
        BeuSound.glass()

        let settings = currentSettings
        let reset = resetGuest

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let patchURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes") else {
                    throw ControllerError.missingPatch
                }

                let source = try Data(contentsOf: patchURL)
                let configured = try AssemblyPatchConfigurator.configure(source: source, settings: settings)
                let configuredHash = Self.sha256(configured)
                let liveState = ControllerLiveState(settings: settings)
                let stateData = try Self.encodeJSON(liveState)
                let configData = Data("{\"testCodePatch\":true,\"resetGuest\":\(reset ? "true" : "false")}\n".utf8)

                let project = PatchProject(
                    name: "BEU Live Controller",
                    bundleIdentifiers: [targetBundle],
                    rules: [
                        PatchRule(
                            bundleID: targetBundle,
                            relativePath: "Documents/Assembly-CSharp-patch.bytes",
                            replacementFilename: "Assembly-CSharp-patch.bytes",
                            replacementData: configured
                        ),
                        PatchRule(
                            bundleID: targetBundle,
                            relativePath: "Documents/localConfig.json",
                            replacementFilename: "localConfig.json",
                            replacementData: configData
                        ),
                        PatchRule(
                            bundleID: targetBundle,
                            relativePath: "Documents/BEUControllerState.json",
                            replacementFilename: "BEUControllerState.json",
                            replacementData: stateData
                        )
                    ]
                )

                _ = try DevicePatchService.apply(project: project)

                guard let rootPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle),
                      ContainerStore.isApplicationContainerPath(rootPath) else {
                    throw ControllerError.targetUnavailable
                }

                let documents = URL(fileURLWithPath: rootPath, isDirectory: true)
                    .appendingPathComponent("Documents", isDirectory: true)
                let patchOut = documents.appendingPathComponent("Assembly-CSharp-patch.bytes")
                let configOut = documents.appendingPathComponent("localConfig.json")
                let stateOut = documents.appendingPathComponent("BEUControllerState.json")

                guard FileManager.default.fileExists(atPath: patchOut.path),
                      FileManager.default.fileExists(atPath: configOut.path),
                      FileManager.default.fileExists(atPath: stateOut.path) else {
                    throw ControllerError.injectVerificationFailed
                }

                let installedPatch = try Data(contentsOf: patchOut)
                guard Self.sha256(installedPatch) == configuredHash else {
                    throw ControllerError.injectVerificationFailed
                }

                DispatchQueue.main.async {
                    packageInfo.configuredSHA256 = configuredHash
                    injected = true
                    injecting = false
                    statusText = "INJECT thành công. Patch/config/state đã được ghi vào target."
                    BeuSound.success()
                }
            } catch {
                DispatchQueue.main.async {
                    injecting = false
                    injected = false
                    packageState = .failed
                    statusText = "Inject thất bại: \(error.localizedDescription)"
                    BeuSound.error()
                }
            }
        }
    }

    private var currentSettings: AssemblyPatchSettings {
        AssemblyPatchSettings(
            aimBot: aimBot,
            aimSilent: aimSilent,
            aimMode: aimMode,
            espLine: espLine,
            espBox: espBox,
            healthBar: healthBar,
            espDistance: espDistance,
            espName: espName,
            noRecoil: noRecoil,
            runSpeed: runSpeed,
            skySpeed: skySpeed,
            healFast: healFast
        )
    }

    private func scheduleLiveSync() {
        liveSyncWorkItem?.cancel()
        guard injected else { return }

        let work = DispatchWorkItem { [settings = currentSettings] in
            pushLiveState(settings)
        }
        liveSyncWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func pushLiveState(_ settings: AssemblyPatchSettings) {
        guard let rootPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle),
              ContainerStore.isApplicationContainerPath(rootPath) else {
            return
        }

        let documents = URL(fileURLWithPath: rootPath, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
        let stateURL = documents.appendingPathComponent("BEUControllerState.json")

        do {
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            let data = try Self.encodeJSON(ControllerLiveState(settings: settings))
            let tempURL = documents.appendingPathComponent(".BEUControllerState-\(UUID().uuidString).tmp")
            try data.write(to: tempURL, options: .atomic)
            if FileManager.default.fileExists(atPath: stateURL.path) {
                _ = try FileManager.default.replaceItemAt(
                    stateURL, withItemAt: tempURL, backupItemName: nil, options: .usingNewMetadataOnly
                )
            } else {
                try FileManager.default.moveItem(at: tempURL, to: stateURL)
            }
        } catch {
            // The next toggle/inject will retry. Keep UI responsive.
        }
    }

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    private func controllerCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    private func featureSectionTitle(_ title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(pinkAccent.opacity(0.72))
                .frame(width: 3, height: 18)
                .clipShape(Capsule())

            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.34))

            Spacer()
        }
        .padding(.top, 7)
    }

    private func resetBinding(_ binding: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { binding.wrappedValue },
            set: { value in
                binding.wrappedValue = value
                if injected { pushLocalConfig(value) }
                BeuSound.toggle()
            }
        )
    }

    private func pushLocalConfig(_ reset: Bool) {
        guard let rootPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle),
              ContainerStore.isApplicationContainerPath(rootPath) else { return }

        let documents = URL(fileURLWithPath: rootPath, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
        let configURL = documents.appendingPathComponent("localConfig.json")
        let data = Data("{\"testCodePatch\":true,\"resetGuest\":\(reset ? "true" : "false")}\n".utf8)

        do {
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            let tempURL = documents.appendingPathComponent(".localConfig-\(UUID().uuidString).tmp")
            try data.write(to: tempURL, options: .atomic)
            if FileManager.default.fileExists(atPath: configURL.path) {
                _ = try FileManager.default.replaceItemAt(
                    configURL, withItemAt: tempURL, backupItemName: nil, options: .usingNewMetadataOnly
                )
            } else {
                try FileManager.default.moveItem(at: tempURL, to: configURL)
            }
        } catch {
            statusText = "Không đồng bộ được localConfig.json."
        }
    }

    private func liveBinding(_ binding: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { binding.wrappedValue },
            set: { value in
                binding.wrappedValue = value
                scheduleLiveSync()
                BeuSound.toggle()
            }
        )
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
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
                .tint(pinkAccent)
                .scaleEffect(0.9)
        }
        .padding(.vertical, 7)
    }

    private func packageRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text(detail)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.34))
            }
            Spacer()
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.75)
                .foregroundStyle(.white.opacity(0.26))
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))
                .textSelection(.enabled)
        }
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func shortHash(_ hash: String) -> String {
        guard hash.count >= 12 else { return hash }
        return String(hash.prefix(8)) + "…" + String(hash.suffix(4))
    }

    private enum PackageState {
        case checking, ready, failed
    }

    private struct PackageInfo {
        let patchBytes: Int
        let patchSHA256: String
        var configuredSHA256: String
        let patchDetail: String

        static let empty = PackageInfo(
            patchBytes: 0,
            patchSHA256: "",
            configuredSHA256: "",
            patchDetail: "Chưa kiểm tra"
        )
    }

    private enum ControllerError: LocalizedError {
        case missingPatch
        case notPrepared
        case targetUnavailable
        case injectVerificationFailed

        var errorDescription: String? {
            switch self {
            case .missingPatch:
                return "Không tìm thấy Assembly-CSharp-patch.bytes trong bundle."
            case .notPrepared:
                return "Chưa có patch đã cấu hình."
            case .targetUnavailable:
                return "Không tìm thấy container của target."
            case .injectVerificationFailed:
                return "Inject xong nhưng không xác minh được resource trong target."
            }
        }
    }
}

// MARK: - Actual Assembly patch configurator

private struct AssemblyPatchSettings: Codable {
    let aimBot: Bool
    let aimSilent: Bool
    let aimMode: Int
    let espLine: Bool
    let espBox: Bool
    let healthBar: Bool
    let espDistance: Bool
    let espName: Bool
    let noRecoil: Bool
    let runSpeed: Bool
    let skySpeed: Bool
    let healFast: Bool
}

private struct ControllerLiveState: Codable {
    let dlt_st: Int
    let dlt_aim: Int
    let dlt_sil: Int
    let dlt_nm: Int

    init(settings: AssemblyPatchSettings) {
        dlt_st = Self.mask(settings)
        dlt_aim = min(max(settings.aimMode, 0), 2)
        dlt_sil = settings.aimSilent ? 1 : 0
        dlt_nm = settings.espName ? 1 : 0
    }

    private static func mask(_ s: AssemblyPatchSettings) -> Int {
        (s.espLine ? 2 : 0)
        | (s.espBox ? 1 : 0)
        | (s.healthBar ? 512 : 0)
        | (s.noRecoil ? 1024 : 0)
        | (s.aimBot ? 8192 : 0)
        | (s.runSpeed ? 16384 : 0)
        | (s.espDistance ? 32768 : 0)
        | (s.skySpeed ? 65536 : 0)
        | (s.healFast ? 131072 : 0)
    }
}

private struct ControllerManifest: Codable {
    let sourceSHA256: String
    let configuredSHA256: String
    let settings: AssemblyPatchSettings
    let resetGuest: Bool
}

private enum AssemblyPatchConfigurator {
    private static let expectedSize = 39_019
    private static let expectedSHA256 = "17a61bd1c7b6bf9be9995458ae58e5a9f04f00816af9b05366fb65588a5fb1b7"

    // Exact method-4 offsets for the supplied 39,019-byte patch.
    // Each instruction is encoded as: Int32 opcode + Int32 operand.
    private static let noRecoilOpOffset = 10_431
    private static let noRecoilOperandOffset = 10_435
    private static let dltStDefaultOpOffset = 13_351
    private static let dltStDefaultOperandOffset = 13_355
    private static let aimModeDefaultOpOffset = 13_415
    private static let aimModeDefaultOperandOffset = 13_419
    private static let silentDefaultOpOffset = 13_479
    private static let silentDefaultOperandOffset = 13_483
    private static let espNameDefaultOpOffset = 13_511
    private static let espNameDefaultOperandOffset = 13_515

    // Headless-live mode: force method 4 to reload PlayerPrefs every OnGUI
    // tick, then return before the old in-game control window is drawn.
    private static let headlessGateOpOffset = 13_327
    private static let headlessGateOperandOffset = 13_331
    private static let headlessReturnOpOffset = 13_551
    private static let headlessReturnOperandOffset = 13_555

    // Actual dlt_st masks proven from the patch's UI/bit-test logic.
    private static let maskESPLine = 2
    private static let maskESPBox = 1
    private static let maskHealthBar = 512
    private static let maskNoRecoil = 1024
    private static let maskAimBot = 8192
    private static let maskRunSpeed = 16384
    private static let maskSkySpeed = 65536
    private static let maskHealFast = 131072
    private static let maskESPDistance = 32768

    static func configure(source: Data, settings: AssemblyPatchSettings) throws -> Data {
        guard source.count == expectedSize else { throw ConfiguratorError.invalidSize(source.count) }
        guard sha256(source) == expectedSHA256 else { throw ConfiguratorError.invalidSourceHash }

        var out = source

        let dltState =
            (settings.espLine ? maskESPLine : 0)
            | (settings.espBox ? maskESPBox : 0)
            | (settings.healthBar ? maskHealthBar : 0)
            | (settings.noRecoil ? maskNoRecoil : 0)
            | (settings.aimBot ? maskAimBot : 0)
            | (settings.runSpeed ? maskRunSpeed : 0)
            | (settings.skySpeed ? maskSkySpeed : 0)
            | (settings.healFast ? maskHealFast : 0)
            | (settings.espDistance ? maskESPDistance : 0)

        // Startup default for dlt_st: PlayerPrefs.GetInt(key, desiredMask)
        writeInt32(&out, at: dltStDefaultOpOffset, value: 180) // Ldc_I4
        writeInt32(&out, at: dltStDefaultOperandOffset, value: dltState)

        // __aimMode startup default: 0 = Cổ, 1 = Đầu, 2 = Bụng.
        let normalizedAimMode = min(max(settings.aimMode, 0), 2)
        writeInt32(&out, at: aimModeDefaultOpOffset, value: 180)
        writeInt32(&out, at: aimModeDefaultOperandOffset, value: normalizedAimMode)

        // __silentOn startup default.
        writeInt32(&out, at: silentDefaultOpOffset, value: 180)
        writeInt32(&out, at: silentDefaultOperandOffset, value: settings.aimSilent ? 1 : 0)

        // __espName startup default.
        writeInt32(&out, at: espNameDefaultOpOffset, value: 180)
        writeInt32(&out, at: espNameDefaultOperandOffset, value: settings.espName ? 1 : 0)

        // No-recoil has a one-time guard field __nrUser. For ON we force that
        // guard true so startup does not clear bit 1024 from dlt_st.
        if settings.noRecoil {
            writeInt32(&out, at: noRecoilOpOffset, value: 180) // Ldc_I4
            writeInt32(&out, at: noRecoilOperandOffset, value: 1)
        } else {
            writeInt32(&out, at: noRecoilOpOffset, value: 144) // Ldsfld
            writeInt32(&out, at: noRecoilOperandOffset, value: 17) // __nrUser
        }

        // Method 4 originally checks __pLoaded and only reads PlayerPrefs once.
        // Replace that gate with `false`, so dlt_st/dlt_aim/dlt_sil/dlt_nm are
        // refreshed from PlayerPrefs on every OnGUI call. Then return before the
        // legacy touch/GUI menu code starts.
        guard readInt32(source, at: headlessGateOpOffset) == 144,
              readInt32(source, at: headlessGateOperandOffset) == 34,
              readInt32(source, at: headlessReturnOpOffset) == 20,
              readInt32(source, at: headlessReturnOperandOffset) == 7 else {
            throw ConfiguratorError.invalidLayout
        }
        writeInt32(&out, at: headlessGateOpOffset, value: 180)
        writeInt32(&out, at: headlessGateOperandOffset, value: 0)
        writeInt32(&out, at: headlessReturnOpOffset, value: 136)
        writeInt32(&out, at: headlessReturnOperandOffset, value: 0)

        guard out.count == expectedSize else { throw ConfiguratorError.invalidOutputSize(out.count) }
        return out
    }

    private static func readInt32(_ data: Data, at offset: Int) -> Int {
        let b0 = UInt32(data[offset])
        let b1 = UInt32(data[offset + 1]) << 8
        let b2 = UInt32(data[offset + 2]) << 16
        let b3 = UInt32(data[offset + 3]) << 24
        return Int(Int32(bitPattern: b0 | b1 | b2 | b3))
    }

    private static func writeInt32(_ data: inout Data, at offset: Int, value: Int) {
        let raw = UInt32(bitPattern: Int32(value))
        data[offset] = UInt8(truncatingIfNeeded: raw)
        data[offset + 1] = UInt8(truncatingIfNeeded: raw >> 8)
        data[offset + 2] = UInt8(truncatingIfNeeded: raw >> 16)
        data[offset + 3] = UInt8(truncatingIfNeeded: raw >> 24)
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private enum ConfiguratorError: LocalizedError {
        case invalidSize(Int)
        case invalidSourceHash
        case invalidOutputSize(Int)
        case invalidLayout

        var errorDescription: String? {
            switch self {
            case .invalidSize(let size):
                return "Patch source có size không đúng: \(size) bytes."
            case .invalidSourceHash:
                return "Patch source không đúng SHA-256 đã đăng ký."
            case .invalidOutputSize(let size):
                return "Patch sau cấu hình bị thay đổi size: \(size) bytes."
            case .invalidLayout:
                return "Patch layout không khớp với base patch đã xác nhận."
            }
        }
    }
}

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
        if let existing = players[name] { return existing }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav")
                ?? Bundle.main.url(forResource: name, withExtension: "caf") else { return nil }
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
        DispatchQueue.main.async { AudioServicesPlaySystemSound(1111) }
    }

    static func error() {
        DispatchQueue.main.async { AudioServicesPlaySystemSound(1073) }
    }

    static func click() { glass() }
}
