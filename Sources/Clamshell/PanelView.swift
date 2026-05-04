import SwiftUI

struct PanelView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            primaryToggles
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

    private var primaryToggles: some View {
        VStack(spacing: 10) {
            alignedToggle("Keep awake until jobs finish", isOn: binding(\.masterEnabled), weight: .semibold)
            alignedToggle("Sleep Mac when settled", isOn: binding(\.autoSleepWhenSettled), weight: .semibold)
        }
    }

    private var sourceToggles: some View {
        VStack(spacing: 10) {
            sourceToggle(.codexApp, keyPath: \.watchCodexApp)
            sourceToggle(.codexCLI, keyPath: \.watchCodexCLI)
            sourceToggle(.claudeCode, keyPath: \.watchClaudeCode)
        }
    }

    private func sourceToggle(_ source: WatchSource, keyPath: WritableKeyPath<AppSettings, Bool>) -> some View {
        alignedToggle(source.title, iconName: iconName(for: source), isOn: binding(keyPath), weight: .medium)
    }

    private func alignedToggle(
        _ title: String,
        iconName: String? = nil,
        isOn: Binding<Bool>,
        weight: Font.Weight
    ) -> some View {
        HStack(spacing: 10) {
            if let iconName {
                Image(systemName: iconName)
                    .frame(width: 20)
                    .foregroundStyle(.primary)
            }

            Text(title)
                .font(.system(size: 14, weight: weight))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 16)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .frame(width: 64, alignment: .trailing)
        }
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
                    if status.active && status.count > 0 {
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
            helperControl

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11, weight: .medium))
        }
    }

    @ViewBuilder
    private var helperControl: some View {
        if model.helperStatus.installed {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.blue)
                Text(model.helperStatus.message)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } else {
            Button {
                model.installHelper()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.slash")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(model.helperInstallMessage ?? "Install Helper")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("Required for closed-lid sleep control")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Install the small pmset helper with administrator approval")
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
