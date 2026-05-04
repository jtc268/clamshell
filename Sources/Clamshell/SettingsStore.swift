import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var values: AppSettings {
        didSet { save() }
    }

    private let key = "Clamshell.settings.v1"

    init(defaults: UserDefaults = .standard) {
        if
            let data = defaults.data(forKey: key),
            var decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            decoded.settleSeconds = max(decoded.settleSeconds, AppSettings.defaults.settleSeconds)
            values = decoded
        } else {
            values = .defaults
        }
    }

    func resetWatchWindow() {
        NotificationCenter.default.post(name: .clamshellResetWatchWindow, object: nil)
    }

    private func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(values) else { return }
        defaults.set(data, forKey: key)
    }
}

extension Notification.Name {
    static let clamshellResetWatchWindow = Notification.Name("dev.clamshell.resetWatchWindow")
}
