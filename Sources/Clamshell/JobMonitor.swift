import Foundation

struct JobMonitor {
    var sessionScanner = CodexSessionScanner()
    var now: () -> Date = Date.init

    func snapshot(settings: AppSettings, watchStartedAt: Date) -> MonitorSnapshot {
        let processes = ProcessTable.snapshot()
        var sources: [SourceStatus] = []

        let codexApp = codexAppStatus(
            enabled: settings.watchCodexApp,
            processes: processes,
            watchStartedAt: watchStartedAt,
            settleSeconds: settings.settleSeconds
        )

        sources.append(codexApp)
        sources.append(codexCLIStatus(
            enabled: settings.watchCodexCLI,
            processes: processes,
            watchStartedAt: watchStartedAt,
            settleSeconds: settings.settleSeconds,
            codexAppIsActive: codexApp.active
        ))
        sources.append(claudeCodeStatus(enabled: settings.watchClaudeCode, processes: processes))

        let activeSources = sources.filter(\.active)
        let active = settings.masterEnabled && !activeSources.isEmpty
        let latestReason = activeSources.first?.reason ?? "No watched jobs are active."

        return MonitorSnapshot(
            checkedAt: now(),
            active: active,
            sources: sources,
            latestReason: latestReason
        )
    }

    private func codexAppStatus(
        enabled: Bool,
        processes: [ProcessInfoSnapshot],
        watchStartedAt: Date,
        settleSeconds: TimeInterval
    ) -> SourceStatus {
        guard enabled else {
            return SourceStatus(source: .codexApp, enabled: false, active: false, reason: "Off", detail: nil, count: 0)
        }

        let appServers = processes.filter { process in
            process.commandLine.contains("/Applications/Codex.app/Contents/Resources/codex")
                && process.commandLine.contains(" app-server")
        }

        if appServers.isEmpty {
            return SourceStatus(
                source: .codexApp,
                enabled: true,
                active: false,
                reason: "Codex App is not running.",
                detail: nil,
                count: 0
            )
        }

        if let recent = recentCodexSessionChange(watchStartedAt: watchStartedAt, settleSeconds: settleSeconds) {
            return SourceStatus(
                source: .codexApp,
                enabled: true,
                active: true,
                reason: "Codex App session updated \(formatAge(recent.age)).",
                detail: recent.url.lastPathComponent,
                count: 1
            )
        }

        return SourceStatus(
            source: .codexApp,
            enabled: true,
            active: false,
            reason: "Codex App is open, no recent job activity.",
            detail: "No Codex session writes inside the settle window.",
            count: 0
        )
    }

    private func codexCLIStatus(
        enabled: Bool,
        processes: [ProcessInfoSnapshot],
        watchStartedAt: Date,
        settleSeconds: TimeInterval,
        codexAppIsActive: Bool
    ) -> SourceStatus {
        guard enabled else {
            return SourceStatus(source: .codexCLI, enabled: false, active: false, reason: "Off", detail: nil, count: 0)
        }

        let matches = processes.filter { process in
            let command = process.commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
            return (command == "codex" || command.hasPrefix("codex ") || command.contains("/codex "))
                && !command.contains(" app-server")
                && !command.contains("/Applications/Codex.app/")
                && !hasAncestor(containing: "/Applications/Codex Terminal.app/", process: process, processes: processes)
                && !command.contains("Clamshell")
                && !command.contains("rg -i")
        }

        let childWork = ProcessTable.descendants(of: Set(matches.map(\.pid)), in: processes).filter { child in
            !isIgnoredCodexCLIChild(child.commandLine)
        }

        if let child = childWork.first {
            return SourceStatus(
                source: .codexCLI,
                enabled: true,
                active: true,
                reason: "Codex CLI child work is running.",
                detail: summarize(child.commandLine),
                count: childWork.count
            )
        }

        if !codexAppIsActive,
           let recent = recentCodexSessionChange(watchStartedAt: watchStartedAt, settleSeconds: settleSeconds)
        {
            return SourceStatus(
                source: .codexCLI,
                enabled: true,
                active: !matches.isEmpty,
                reason: matches.isEmpty ? "No Codex CLI process found." : "Codex session updated \(formatAge(recent.age)).",
                detail: matches.isEmpty ? nil : recent.url.lastPathComponent,
                count: matches.count
            )
        }

        return SourceStatus(
            source: .codexCLI,
            enabled: true,
            active: false,
            reason: matches.isEmpty ? "No Codex CLI process found." : "Codex CLI is open, no recent job activity.",
            detail: matches.first.map { summarize($0.commandLine) },
            count: matches.count
        )
    }

    private func claudeCodeStatus(enabled: Bool, processes: [ProcessInfoSnapshot]) -> SourceStatus {
        guard enabled else {
            return SourceStatus(source: .claudeCode, enabled: false, active: false, reason: "Off", detail: nil, count: 0)
        }

        let matches = processes.filter { process in
            let command = process.commandLine.lowercased()
            return (
                command == "claude"
                    || command.hasPrefix("claude ")
                    || command.contains("/claude ")
                    || command.contains("claude-code")
                    || command.contains("@anthropic-ai/claude-code")
                    || command.contains("/resources/native-binary/claude")
                    || command.hasSuffix("/claude")
            )
            && !command.contains("/applications/claude.app/")
            && !command.contains("clamshell")
        }

        return SourceStatus(
            source: .claudeCode,
            enabled: true,
            active: !matches.isEmpty,
            reason: matches.isEmpty ? "No Claude Code process found." : "Claude Code process is running.",
            detail: matches.first.map { summarize($0.commandLine) },
            count: matches.count
        )
    }

    private func isIgnoredCodexCLIChild(_ command: String) -> Bool {
        let ignored = [
            "node_repl",
            "SkyComputerUseClient mcp",
            "chrome_crashpad_handler"
        ]

        return ignored.contains { command.contains($0) }
    }

    private func hasAncestor(
        containing needle: String,
        process: ProcessInfoSnapshot,
        processes: [ProcessInfoSnapshot]
    ) -> Bool {
        let byPID = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
        var current = process
        var seen = Set<Int32>()

        while let parent = byPID[current.ppid], !seen.contains(parent.pid) {
            if parent.commandLine.contains(needle) {
                return true
            }
            seen.insert(parent.pid)
            current = parent
        }

        return false
    }

    private func recentCodexSessionChange(
        watchStartedAt: Date,
        settleSeconds: TimeInterval
    ) -> (url: URL, age: TimeInterval)? {
        guard let latest = sessionScanner.latestSessionChange(since: watchStartedAt) else {
            return nil
        }

        let age = now().timeIntervalSince(latest.modifiedAt)
        guard age <= settleSeconds else {
            return nil
        }

        return (latest.url, age)
    }

    private func summarize(_ command: String) -> String {
        if command.count <= 96 { return command }
        return String(command.prefix(93)) + "..."
    }

    private func formatAge(_ seconds: TimeInterval) -> String {
        if seconds < 1 { return "just now" }
        return "\(Int(seconds.rounded()))s ago"
    }
}
