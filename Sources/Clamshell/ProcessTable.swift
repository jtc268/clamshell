import Foundation

struct ProcessInfoSnapshot: Codable {
    let pid: Int32
    let ppid: Int32
    let commandLine: String
}

struct ProcessTable {
    static func snapshot() -> [ProcessInfoSnapshot] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,ppid=,command="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap(parseLine)
    }

    static func descendants(of roots: Set<Int32>, in processes: [ProcessInfoSnapshot]) -> [ProcessInfoSnapshot] {
        guard !roots.isEmpty else { return [] }

        var childrenByParent: [Int32: [ProcessInfoSnapshot]] = [:]
        for process in processes {
            childrenByParent[process.ppid, default: []].append(process)
        }

        var queue = Array(roots)
        var seen = Set<Int32>()
        var result: [ProcessInfoSnapshot] = []

        while let parent = queue.popLast() {
            for child in childrenByParent[parent, default: []] where !seen.contains(child.pid) {
                seen.insert(child.pid)
                result.append(child)
                queue.append(child.pid)
            }
        }

        return result
    }

    private static func parseLine(_ line: Substring) -> ProcessInfoSnapshot? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count == 3, let pid = Int32(parts[0]), let ppid = Int32(parts[1]) else {
            return nil
        }

        return ProcessInfoSnapshot(pid: pid, ppid: ppid, commandLine: String(parts[2]))
    }
}
