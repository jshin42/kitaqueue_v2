import Foundation

/// Product identifiers for StoreKit 2
enum IAPProducts: String, CaseIterable {
    case removeAds = "com.kitaqueue.remove_ads"
    case starterPack = "com.kitaqueue.starter_pack"
    case dojoThemePack = "com.kitaqueue.cosmetic_theme_pack_01"
    case bladeTrailPack = "com.kitaqueue.cosmetic_trail_pack_01"

    var displayName: String {
        switch self {
        case .removeAds: "Remove Ads"
        case .starterPack: "Starter Pack"
        case .dojoThemePack: "Dojo Theme Pack"
        case .bladeTrailPack: "Blade Trail Pack"
        }
    }

    var description: String {
        switch self {
        case .removeAds: "Eliminate interstitial ads forever"
        case .starterPack: "Remove Ads + 200 Coins + 5 Tokens + Exclusive Skin"
        case .dojoThemePack: "Premium dojo visual theme"
        case .bladeTrailPack: "Premium blade trail effects"
        }
    }

    var icon: String {
        switch self {
        case .removeAds: "xmark.circle.fill"
        case .starterPack: "star.fill"
        case .dojoThemePack: "paintbrush.fill"
        case .bladeTrailPack: "sparkles"
        }
    }

    var accentColorName: String {
        switch self {
        case .removeAds: "cyan"
        case .starterPack: "yellow"
        case .dojoThemePack: "purple"
        case .bladeTrailPack: "orange"
        }
    }
}
