import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot: MonitorSnapshot = .empty
    @Published private(set) var helperStatus: HelperStatus = .missing
    @Published private(set) var helperInstallMessage: String?
    @Published private(set) var isHoldingSleep = false

    let settings = SettingsStore()

    private let monitor = JobMonitor()
    private let sleepController = SleepController()
    private var timer: Timer?
    private var watchStartedAt = Date()
    private var heldDuringThisRun = false

    init() {
        helperStatus = sleepController.helperStatus()
        NotificationCenter.default.addObserver(
            forName: .clamshellResetWatchWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.watchStartedAt = Date()
                self?.evaluate()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.sleepController.release(autoSleep: false)
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluate() }
        }
        evaluate()
    }

    func evaluate() {
        let current = monitor.snapshot(settings: settings.values, watchStartedAt: watchStartedAt)
        snapshot = current
        helperStatus = sleepController.helperStatus()

        guard settings.values.masterEnabled else {
            if isHoldingSleep {
                sleepController.release(autoSleep: false)
                isHoldingSleep = false
            }
            heldDuringThisRun = false
            return
        }

        if current.active {
            sleepController.hold(reason: current.latestReason)
            isHoldingSleep = true
            heldDuringThisRun = true
        } else if isHoldingSleep {
            sleepController.release(autoSleep: settings.values.autoSleepWhenSettled && heldDuringThisRun)
            isHoldingSleep = false
            heldDuringThisRun = false
        }
    }

    func installHelper() {
        helperInstallMessage = "Installing helper..."
        helperInstallMessage = sleepController.installHelper()
        helperStatus = sleepController.helperStatus()
    }
}
