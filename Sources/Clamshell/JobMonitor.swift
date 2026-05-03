import Foundation

struct JobMonitor {
    var sessionScanner = CodexSessionScanner()
    var now: () -> Date = Date.init

    func snapshot(settings: AppSettings, watchStartedAt: Date) -> MonitorSnapshot {
        let processes = ProcessTable.snapshot()
        var sources: [SourceStatus] = []

        sources.append(codexAppStatus(
            enabled: settings.watchCodexApp,
            processes: processes,
            watchStartedAt: watchStartedAt,
            settleSeconds: settings.settleSeconds
        ))
        sources.append(codexCLIStatus(enabled: settings.watchCodexCLI, processes: processes))
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

        let descendants = ProcessTable.descendants(of: Set(appServers.map(\.pid)), in: processes)
        let activeChildren = descendants.filter { child in
            !isIgnoredCodexAppChild(child.commandLine)
        }

        if let child = activeChildren.first {
            return SourceStatus(
                source: .codexApp,
                enabled: true,
                active: true,
                reason: "Codex App child work is running.",
                detail: summarize(child.commandLine),
                count: activeChildren.count
            )
        }

        if let latest = sessionScanner.latestSessionChange(since: watchStartedAt) {
            let age = now().timeIntervalSince(latest.modifiedAt)
            if age <= settleSeconds {
                return SourceStatus(
                    source: .codexApp,
                    enabled: true,
                    active: true,
                    reason: "Codex App session updated \(formatSeconds(age)) ago.",
                    detail: latest.url.lastPathComponent,
                    count: appServers.count
                )
            }
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

        return SourceStatus(
            source: .codexApp,
            enabled: true,
            active: false,
            reason: "Codex App is settled.",
            detail: "No session writes inside the settle window.",
            count: appServers.count
        )
    }

    private func codexCLIStatus(enabled: Bool, processes: [ProcessInfoSnapshot]) -> SourceStatus {
        guard enabled else {
            return SourceStatus(source: .codexCLI, enabled: false, active: false, reason: "Off", detail: nil, count: 0)
        }

        let matches = processes.filter { process in
            let command = process.commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
            return (command == "codex" || command.hasPrefix("codex ") || command.contains("/codex "))
                && !command.contains(" app-server")
                && !command.contains("/Applications/Codex.app/")
                && !command.contains("Clamshell")
                && !command.contains("rg -i")
        }

        return SourceStatus(
            source: .codexCLI,
            enabled: true,
            active: !matches.isEmpty,
            reason: matches.isEmpty ? "No Codex CLI process found." : "Codex CLI process is running.",
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

    private func isIgnoredCodexAppChild(_ command: String) -> Bool {
        let ignored = [
            "node_repl",
            "SkyComputerUseClient mcp",
            "@upstash/context7-mcp",
            " app-server",
            "chrome_crashpad_handler",
            "Codex Helper"
        ]

        return ignored.contains { command.contains($0) }
    }

    private func summarize(_ command: String) -> String {
        if command.count <= 96 { return command }
        return String(command.prefix(93)) + "..."
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        if seconds < 1 { return "just now" }
        return "\(Int(seconds.rounded()))s"
    }
}
