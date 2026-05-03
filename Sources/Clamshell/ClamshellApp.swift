import SwiftUI

@main
struct ClamshellApp: App {
    @StateObject private var model = AppModel()

    init() {
        if CommandLine.arguments.contains("--probe") {
            let settings = AppSettings(
                masterEnabled: true,
                watchCodexApp: true,
                watchCodexCLI: true,
                watchClaudeCode: true,
                autoSleepWhenSettled: false,
                settleSeconds: 90
            )
            let snapshot = JobMonitor().snapshot(
                settings: settings,
                watchStartedAt: Date().addingTimeInterval(-120)
            )
            if let data = try? JSONEncoder.clamshell.encode(snapshot),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
            Foundation.exit(snapshot.active ? 0 : 2)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .environmentObject(model)
        } label: {
            Image(systemName: model.isHoldingSleep ? "bolt.shield.fill" : "bolt.shield")
        }
        .menuBarExtraStyle(.window)
    }
}

extension JSONEncoder {
    static var clamshell: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
