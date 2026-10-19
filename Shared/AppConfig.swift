import Foundation

/// The one file to edit per app. Compiled into the app and the widget: Foundation only.
enum AppConfig {
    // MARK: Identity
    static let appName = "Limb Log"
    static let bundleID = "com.example.limb-log"
    static let appGroupID = "group.com.example.limb-log"
    static let appStoreID = ""

    // MARK: Sync
    static let iCloudSyncEnabled = false

    // MARK: StoreKit
    static let productPrefix = bundleID.replacingOccurrences(of: "-", with: "")
    static let annualProductID = "\(productPrefix).pro.annual"
    static let lifetimeProductID = "\(productPrefix).pro.lifetime"

    // MARK: Links
    static let supportEmail = "support@somexai.com"
    static let privacyPolicyURL = URL(string: "https://somexai.com/privacy/limb-log/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: Copy
    static let entryNoun = "Measurement"
    static let entryNounPlural = "Measurements"
    static let exportFileStem = "limb-log"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "ruler", title: "Measure at the same points, every time",
                       body: "Set the tape points once (wrist, 10 cm, 20 cm…). Each time, type the numbers in; the app remembers the last ones."),
        OnboardingPage(symbol: "chart.xyaxis.line", title: "See the volume, not just the numbers",
                       body: "Circumferences become an estimated limb volume with the truncated-cone formula therapists use. Affected versus other side, over time."),
        OnboardingPage(symbol: "doc.text.fill", title: "Hand your therapist the full picture",
                       body: "Measurements, volume trend, symptoms and photos in one PDF for the next appointment. Everything stays on the phone."),
    ]

    static let paywallSymbol = "checkmark.seal.fill"
    static let paywallHeadline = "Unlock \(appName)"
    static let paywallBenefits = [
        "Unlimited measurements, both limbs",
        "Estimated volume and side-to-side difference",
        "Trend chart, symptoms and photos",
        "PDF report for your lymphedema therapist",
        "Measurement reminders and widget",
    ]

    static let disclaimer = "\(appName) records the measurements you take and estimates volume from them. It does not diagnose lymphedema or replace your therapist's measurements. Sudden swelling, redness, warmth or fever can mean infection; contact your clinic promptly."

    // MARK: How-to guide
    static let howToIntro = "From install to your first report in five short steps."
    static let howTo: [HowToStep] = [
        HowToStep(symbol: "person.crop.circle", title: "Set up the limb",
                  body: "On Home, tap Set Up. Choose arm or leg, the affected side, and keep or edit the tape points. Arms default to the wrist and every 10 cm above it; legs to the ankle and every 10 cm above it."),
        HowToStep(symbol: "ruler", title: "Measure both sides",
                  body: "Tap Measure now, pick the side, and type each circumference. Measure the other side the same day so the app can compare them. Same time of day, same posture, tape snug but not tight.",
                  tip: "Say \"Log a measurement in Limb Log\" to Siri to open this screen."),
        HowToStep(symbol: "bandage", title: "Log symptoms and therapy",
                  body: "Tap Log symptoms: heaviness, tightness, pain, skin signs, what you did (manual drainage, pump, bandaging, garment hours)."),
        HowToStep(symbol: "chart.xyaxis.line", title: "Watch the trend",
                  body: "History shows estimated volume for each side over time and every measurement. Tap one to fix a number."),
        HowToStep(symbol: "doc.text", title: "Bring the report",
                  body: "Report tab → PDF report. Baseline, latest, change, side-to-side difference, the chart, every measurement and your symptom notes."),
    ]

    /// Display prices used only by DEBUG screenshot runs (`-mockPrices`). Keep in sync with StoreKit/Products.storekit.
    static let mockPrices = (annual: "$9.99", lifetime: "$24.99")

    // MARK: Behaviour
    static let reviewAfterSuccesses = 3
    static let defaultMeasureEveryDays = 7
    /// Measurements of the two sides taken within this many days are compared.
    static let pairWindowDays = 3
}

struct HowToStep: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
    var tip: String? = nil
}

struct OnboardingPage: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
}
