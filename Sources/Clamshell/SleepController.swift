import Foundation
import IOKit.pwr_mgt

final class SleepController {
    private let helperPath = "/usr/local/libexec/clamshell-helper"
    private var assertionID = IOPMAssertionID(0)
    private var hasAssertion = false
    private var closedLidModeEnabled = false

    func hold(reason: String) {
        if !hasAssertion {
            var id = IOPMAssertionID(0)
            let status = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &id
            )

            if status == kIOReturnSuccess {
                assertionID = id
                hasAssertion = true
            }
        }

        if !closedLidModeEnabled, helperStatus().installed {
            _ = runHelper("enable")
            closedLidModeEnabled = true
        }
    }

    func release(autoSleep: Bool) {
        if closedLidModeEnabled {
            _ = runHelper("disable")
            closedLidModeEnabled = false
        }

        if hasAssertion {
            IOPMAssertionRelease(assertionID)
            hasAssertion = false
            assertionID = 0
        }

        if autoSleep, helperStatus().installed {
            _ = runHelper("sleepnow")
        }
    }

    func helperStatus() -> HelperStatus {
        guard FileManager.default.isExecutableFile(atPath: helperPath) else {
            return .missing
        }

        let output = runHelper("status").output
        let sleepDisabled = output
            .split(separator: "\n")
            .first { $0.contains("SleepDisabled") }
            .map { $0.contains("1") }

        return HelperStatus(
            installed: true,
            sleepDisabled: sleepDisabled,
            message: sleepDisabled == true ? "Closed-lid hold is armed." : "Closed-lid hold is available."
        )
    }

    private func runHelper(_ action: String) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: helperPath)
        process.arguments = [action]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (-1, error.localizedDescription)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}
