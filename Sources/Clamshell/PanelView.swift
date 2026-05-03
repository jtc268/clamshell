import SwiftUI

struct PanelView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            mainToggle
            sourceToggles
            statusList
            Divider()
            footer
        }
        .padding(18)
        .frame(width: 360)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 38, height: 38)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Clamshell")
                    .font(.system(size: 18, weight: .semibold))
                Text(model.isHoldingSleep ? "Holding sleep" : "Ready")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(model.isHoldingSleep ? .green : .secondary)
            }

            Spacer()

            Button {
                model.evaluate()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh status")
        }
    }

    private var mainToggle: some View {
        Toggle(isOn: binding(\.masterEnabled)) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Keep awake until jobs finish")
                    .font(.system(size: 14, weight: .semibold))
                Text(model.snapshot.latestReason)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .toggleStyle(.switch)
    }

    private var sourceToggles: some View {
        VStack(spacing: 8) {
            sourceToggle(.codexApp, keyPath: \.watchCodexApp)
            sourceToggle(.codexCLI, keyPath: \.watchCodexCLI)
            sourceToggle(.claudeCode, keyPath: \.watchClaudeCode)

            Toggle("Sleep Mac when settled", isOn: binding(\.autoSleepWhenSettled))
                .toggleStyle(.switch)
        }
    }

    private func sourceToggle(_ source: WatchSource, keyPath: WritableKeyPath<AppSettings, Bool>) -> some View {
        HStack {
            Label(source.title, systemImage: iconName(for: source))
            Spacer()
            Toggle("", isOn: binding(keyPath))
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .font(.system(size: 13, weight: .medium))
    }

    private var statusList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(model.snapshot.sources) { status in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: status.active ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(status.active ? .green : .secondary)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(status.source.title)
                            .font(.system(size: 12, weight: .semibold))
                        Text(status.reason)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if let detail = status.detail {
                            Text(detail)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)
                    if status.count > 0 {
                        Text("\(status.count)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: model.helperStatus.installed ? "lock.shield.fill" : "lock.slash")
                .foregroundStyle(model.helperStatus.installed ? .blue : .orange)
            Text(model.helperStatus.message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11, weight: .medium))
        }
    }

    private func binding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.settings.values[keyPath: keyPath] },
            set: { newValue in
                model.settings.values[keyPath: keyPath] = newValue
                model.settings.resetWatchWindow()
                model.evaluate()
            }
        )
    }

    private func iconName(for source: WatchSource) -> String {
        switch source {
        case .codexApp: "app.connected.to.app.below.fill"
        case .codexCLI: "terminal.fill"
        case .claudeCode: "chevron.left.forwardslash.chevron.right"
        }
    }
}
