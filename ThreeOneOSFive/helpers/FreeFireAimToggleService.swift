import Foundation

struct BundledAimPatch: Identifiable, Hashable {
    let id: String
    let title: String
    let resourceName: String
}

enum FreeFireBundledPatchIO {
    static func packageURL(resourceName: String, subdirectory: String) -> URL? {
        let name = (resourceName as NSString).deletingPathExtension
        let ext = (resourceName as NSString).pathExtension
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    static func decodeProject(resourceName: String, subdirectory: String) throws -> PatchProject {
        guard let url = packageURL(resourceName: resourceName, subdirectory: subdirectory) else {
            throw PatchPackageError.unsupportedFormat
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        return try PatchPackageCodec.decode(data, password: nil).project
    }

    static func apply(resourceName: String, subdirectory: String) throws {
        let project = try decodeProject(resourceName: resourceName, subdirectory: subdirectory)
        _ = try DevicePatchService.apply(project: project)
    }

    static func restore(resourceName: String, subdirectory: String) throws {
        let project = try decodeProject(resourceName: resourceName, subdirectory: subdirectory)
        guard let receipt = DevicePatchService.latestReceipt(projectID: project.id) else { return }
        try DevicePatchService.restore(receipt: receipt)
    }

    static func isApplied(resourceName: String, subdirectory: String) -> Bool {
        guard let project = try? decodeProject(resourceName: resourceName, subdirectory: subdirectory) else {
            return false
        }
        return DevicePatchService.latestReceipt(projectID: project.id) != nil
    }
}

enum FreeFireAimToggleService {
    private static let subdirectory = "BundledPatches/FFTHAim"

    static let patches: [BundledAimPatch] = {
        if let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: "catalog", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
            let mapped = rows.compactMap { row -> BundledAimPatch? in
                guard let id = row["id"], let title = row["title"], let resource = row["resource"] else { return nil }
                return BundledAimPatch(id: id, title: title, resourceName: resource)
            }
            if !mapped.isEmpty { return mapped }
        }
        return [
            BundledAimPatch(id: "aim_body", title: "Aim Body", resourceName: "Aim_Body.1411"),
            BundledAimPatch(id: "aim_co", title: "Aim Cổ", resourceName: "Aim_Co.1411"),
            BundledAimPatch(id: "aim_keo", title: "Aim Kéo", resourceName: "Aim_Keo.1411"),
            BundledAimPatch(id: "aim_nguc", title: "Aim Ngực", resourceName: "Aim_Nguc.1411"),
            BundledAimPatch(id: "magic_bullet", title: "Magic Bullet", resourceName: "Magic_Bullet.1411"),
        ]
    }()

    static func apply(patch: BundledAimPatch) throws {
        try FreeFireBundledPatchIO.apply(resourceName: patch.resourceName, subdirectory: subdirectory)
    }

    static func restore(patch: BundledAimPatch) throws {
        try FreeFireBundledPatchIO.restore(resourceName: patch.resourceName, subdirectory: subdirectory)
    }

    static func isApplied(patch: BundledAimPatch) -> Bool {
        FreeFireBundledPatchIO.isApplied(resourceName: patch.resourceName, subdirectory: subdirectory)
    }
}
