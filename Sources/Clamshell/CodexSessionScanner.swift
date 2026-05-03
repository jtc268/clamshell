import Foundation

struct CodexSessionScanner {
    let fileManager: FileManager
    let homeDirectory: URL

    init(fileManager: FileManager = .default, homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory
    }

    func latestSessionChange(since watchStartedAt: Date) -> (url: URL, modifiedAt: Date)? {
        let roots = [
            homeDirectory.appendingPathComponent(".codex/sessions"),
            homeDirectory.appendingPathComponent(".codex/archived_sessions")
        ]

        var latest: (url: URL, modifiedAt: Date)?
        let floor = watchStartedAt.addingTimeInterval(-10)

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator where url.pathExtension == "jsonl" {
                guard
                    let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                    values.isRegularFile == true,
                    let modifiedAt = values.contentModificationDate,
                    modifiedAt >= floor
                else {
                    continue
                }

                if latest == nil || modifiedAt > latest!.modifiedAt {
                    latest = (url, modifiedAt)
                }
            }
        }

        return latest
    }
}
