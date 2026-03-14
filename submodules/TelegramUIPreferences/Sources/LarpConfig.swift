/*
 LARP — Local profile overrides (client-side only)
 Pseudo, aliases, phone, spoof
 */
import Foundation
import Postbox
import TelegramCore

public final class LarpConfig {
    public static let shared = LarpConfig()
    
    private let defaults = UserDefaults.standard
    private let prefix = "larp_"
    
    private init() {}
    
    // MARK: - Custom username
    public var customUsername: String {
        get { defaults.string(forKey: prefix + "username") ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespaces), forKey: prefix + "username") }
    }
    
    public var hasCustomUsername: Bool { !customUsername.isEmpty }
    
    // MARK: - Custom phone
    public var customPhone: String {
        get { defaults.string(forKey: prefix + "phone") ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespaces), forKey: prefix + "phone") }
    }
    
    public var hasCustomPhone: Bool { !customPhone.isEmpty }
    
    // MARK: - Aliases (format: @alias:price @other:123)
    public var aliasesRaw: String {
        get { defaults.string(forKey: prefix + "aliases") ?? "" }
        set { defaults.set(newValue, forKey: prefix + "aliases") }
    }
    
    public var hasAliases: Bool { !aliasesRaw.trimmingCharacters(in: .whitespaces).isEmpty }
    
    public struct FragmentAlias {
        public let name: String
        public let price: Double
    }
    
    public var aliases: [FragmentAlias] {
        parseAliases(aliasesRaw)
    }
    
    private func parseAliases(_ raw: String) -> [FragmentAlias] {
        var result: [FragmentAlias] = []
        let parts = raw.split(separator: " ").map { String($0) }
        for part in parts {
            var item = part
            if item.hasPrefix("@") {
                item = String(item.dropFirst())
            }
            if item.isEmpty { continue }
            if let colonPos = item.firstIndex(of: ":") {
                let name = String(item[..<colonPos])
                let priceStr = String(item[item.index(after: colonPos)...])
                let price = Double(priceStr) ?? 0
                if !name.isEmpty {
                    result.append(FragmentAlias(name: name, price: price))
                }
            } else {
                result.append(FragmentAlias(name: item, price: 0))
            }
        }
        return result
    }
    
    // MARK: - Spoof target (show as another user)
    public var spoofTargetPeerId: PeerId? {
        get {
            let raw = defaults.string(forKey: prefix + "spoofTarget") ?? ""
            if let id = Int64(raw), id != 0 {
                return PeerId(id)
            }
            return nil
        }
        set {
            if let pid = newValue {
                defaults.set(String(pid.toInt64()), forKey: prefix + "spoofTarget")
            } else {
                defaults.removeObject(forKey: prefix + "spoofTarget")
            }
        }
    }
    
    public var hasSpoofTarget: Bool { spoofTargetPeerId != nil }
    
    // MARK: - Peer overrides (customize how others appear)
    public struct OtherPeerOverride {
        public var customName: String
        public var customUsername: String
        public var customPhone: String
    }
    
    private func overrideKey(_ peerId: UInt64) -> String {
        "\(prefix)override_\(peerId)"
    }
    
    public func hasOverride(_ peerId: UInt64) -> Bool {
        defaults.dictionary(forKey: overrideKey(peerId)) != nil
    }
    
    public func peerOverride(_ peerId: UInt64) -> OtherPeerOverride? {
        guard let dict = defaults.dictionary(forKey: overrideKey(peerId)) else { return nil }
        return OtherPeerOverride(
            customName: dict["name"] as? String ?? "",
            customUsername: dict["username"] as? String ?? "",
            customPhone: dict["phone"] as? String ?? ""
        )
    }
    
    public func setPeerOverride(_ peerId: UInt64, _ ov: OtherPeerOverride) {
        defaults.set([
            "name": ov.customName,
            "username": ov.customUsername,
            "phone": ov.customPhone
        ], forKey: overrideKey(peerId))
    }
    
    public func removePeerOverride(_ peerId: UInt64) {
        defaults.removeObject(forKey: overrideKey(peerId))
    }
    
    // MARK: - Active check
    public var isActive: Bool {
        hasCustomUsername || hasCustomPhone || hasAliases || hasSpoofTarget
    }
    
    public func reset() {
        customUsername = ""
        customPhone = ""
        aliasesRaw = ""
        spoofTargetPeerId = nil
        let keys = defaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix(prefix + "override_") {
            defaults.removeObject(forKey: key)
        }
    }
}
