import Foundation

enum WatchSource: String, CaseIterable, Codable, Identifiable {
    case codexApp
    case codexCLI
    case claudeCode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .codexApp: "Codex App"
        case .codexCLI: "Codex CLI"
        case .claudeCode: "Cloud Code CLI"
        }
    }

    var shortTitle: String {
        switch self {
        case .codexApp: "App"
        case .codexCLI: "CLI"
        case .claudeCode: "Cloud"
        }
    }
}

struct SourceStatus: Identifiable, Codable {
    var id: WatchSource { source }

    let source: WatchSource
    let enabled: Bool
    let active: Bool
    let reason: String
    let detail: String?
    let count: Int
}

struct MonitorSnapshot: Codable {
    let checkedAt: Date
    let active: Bool
    let sources: [SourceStatus]
    let latestReason: String

    static let empty = MonitorSnapshot(
        checkedAt: .now,
        active: false,
        sources: [],
        latestReason: "No checks have run yet."
    )
}

struct AppSettings: Codable {
    var masterEnabled: Bool
    var watchCodexApp: Bool
    var watchCodexCLI: Bool
    var watchClaudeCode: Bool
    var autoSleepWhenSettled: Bool
    var settleSeconds: TimeInterval

    static let defaults = AppSettings(
        masterEnabled: false,
        watchCodexApp: true,
        watchCodexCLI: true,
        watchClaudeCode: false,
        autoSleepWhenSettled: true,
        settleSeconds: 90
    )
}

struct HelperStatus: Codable {
    let installed: Bool
    let sleepDisabled: Bool?
    let message: String

    static let missing = HelperStatus(
        installed: false,
        sleepDisabled: nil,
        message: "Helper not installed."
    )
}
