import Foundation
import Combine

struct TerminalLine: Identifiable, Equatable {
    enum Style: String, Codable {
        case command
        case output
        case error
        case info
        case success
    }

    let id: UUID
    let text: String
    let style: Style

    init(_ text: String, _ style: Style = .output) {
        self.id = UUID()
        self.text = text
        self.style = style
    }
}

final class SandboxShell: ObservableObject {
    final class Node {
        let name: String
        let isDirectory: Bool
        var content: String
        var children: [String: Node]
        var modifiedAt: Date

        init(name: String, isDirectory: Bool, content: String = "", children: [String: Node] = [:], modifiedAt: Date = Date()) {
            self.name = name
            self.isDirectory = isDirectory
            self.content = content
            self.children = children
            self.modifiedAt = modifiedAt
        }
    }

    @Published private(set) var lines: [TerminalLine] = []
    @Published private(set) var cwd: [String] = ["home", "muse"]

    private let root = Node(name: "", isDirectory: true)
    private let home: [String] = ["home", "muse"]
    private let userName = "muse"
    private let hostName = "devmuse"
    private var history: [String] = []
    private let startedAt = Date()

    private lazy var stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private lazy var clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    init() {
        seed()
        lines.append(TerminalLine("Muse Linux 1.0 (arm64) - 虚拟沙盒", .info))
        lines.append(TerminalLine("输入 help 查看可用命令。", .info))
        lines.append(TerminalLine("", .output))
    }

    var displayPath: String {
        if cwd == home { return "~" }
        if cwd.starts(with: home) {
            return "~/" + cwd.dropFirst(home.count).joined(separator: "/")
        }
        return "/" + cwd.joined(separator: "/")
    }

    var prompt: String {
        "\(userName)@\(hostName):\(displayPath)$"
    }

    var commandCount: Int {
        history.count
    }

    func run(_ raw: String) -> Bool {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append(TerminalLine("\(prompt) \(input)", .command))
        guard !input.isEmpty else { return false }
        if history.last != input {
            history.append(input)
        }

        let tokens = tokenize(input)
        guard let command = tokens.first else { return false }

        var arguments: [String] = []
        var redirectPath: String?
        var shouldAppend = false
        var index = 1
        while index < tokens.count {
            let token = tokens[index]
            if token == ">" || token == ">>" {
                guard index + 1 < tokens.count else {
                    lines.append(TerminalLine("语法错误：重定向缺少目标路径。", .error))
                    return false
                }
                redirectPath = tokens[index + 1]
                shouldAppend = token == ">>"
                index += 2
                continue
            }
            arguments.append(token)
            index += 1
        }

        let result = execute(command, arguments)

        if let target = redirectPath {
            let text = result.lines.map { $0.text }.joined(separator: "\n")
            if let failure = writeToFile(target, text: text, append: shouldAppend) {
                lines.append(failure)
            }
            return false
        }

        if result.clear {
            lines.removeAll()
            return true
        }

        lines.append(contentsOf: result.lines)
        return false
    }

    func clear() {
        lines.removeAll()
    }

    private func seed() {
        createDirectory(["home", "muse", "notes"])
        createDirectory(["home", "muse", "projects", "devmuse", "Sources"])
        createDirectory(["etc"])
        createDirectory(["var", "log"])
        createDirectory(["usr", "bin"])
        createDirectory(["usr", "local", "bin"])
        writeFile(["etc", "os-release"], content: "NAME=\"Muse Linux\"\nVERSION=\"1.0\"\nID=muse\nPRETTY_NAME=\"Muse Linux 1.0\"\n")
        writeFile(["home", "muse", ".bashrc"], content: "export PS1=\"\\u@\\h:\\w$ \"\nalias ll=\"ls -l\"\n")
        writeFile(["home", "muse", "notes", "todo.md"], content: "# 待办\n\n- 发布第一个 IPA\n- 验证离线启动\n- 整理发布清单\n")
        writeFile(["home", "muse", "projects", "devmuse", "README.md"], content: "# DevMuse\n\n本地优先的 iOS 开发助手。\n")
        writeFile(["home", "muse", "projects", "devmuse", "Sources", "main.swift"], content: "print(\"hello from the sandbox\")\n")
        writeFile(["var", "log", "boot.log"], content: "[ok] mount virtual filesystem\n[ok] start muse shell\n[ok] sandbox ready\n")
    }

    private func execute(_ command: String, _ args: [String]) -> (lines: [TerminalLine], clear: Bool) {
        switch command {
        case "help":
            return (helpLines(), false)
        case "clear":
            return ([], true)
        case "pwd":
            return ([TerminalLine("/" + cwd.joined(separator: "/"))], false)
        case "ls":
            return (listLines(args), false)
        case "cd":
            return changeDirectory(args)
        case "cat":
            return concatenate(args)
        case "echo":
            return ([TerminalLine(args.joined(separator: " "))], false)
        case "mkdir":
            return makeDirectory(args)
        case "touch":
            return touchFile(args)
        case "rm":
            return removePath(args)
        case "tree":
            return tree(args)
        case "grep":
            return grepLines(args)
        case "wc":
            return wordCount(args)
        case "whoami":
            return ([TerminalLine(userName)], false)
        case "uname":
            return ([TerminalLine("Linux \(hostName) 1.0.0-arm64 #1 SMP Muse GNU/Linux")], false)
        case "date":
            return ([TerminalLine(clockFormatter.string(from: Date()))], false)
        case "uptime":
            return ([TerminalLine(uptimeText())], false)
        case "env":
            return (envLines(), false)
        case "history":
            return (historyLines(), false)
        case "exit":
            return ([TerminalLine("这里是设备内的虚拟沙盒，不会退出应用。", .info)], false)
        default:
            return ([TerminalLine("未找到命令：\(command)。输入 help 查看可用命令。", .error)], false)
        }
    }

    private func helpLines() -> [TerminalLine] {
        let rows = [
            ("ls [-l|-a] <path>", "列出目录内容"),
            ("cd <path>", "切换目录"),
            ("pwd", "显示当前路径"),
            ("cat <file>", "查看文件内容"),
            ("echo <text>", "输出文本，支持 > 与 >> 重定向"),
            ("mkdir [-p] <dir>", "创建目录"),
            ("touch <file>", "创建空文件"),
            ("rm [-r] <path>", "删除文件或目录"),
            ("tree [path]", "以树形显示目录"),
            ("grep [-i] <pattern> <file>", "搜索文本"),
            ("wc <file>", "统计行数、词数与字符数"),
            ("whoami / uname / date", "查看用户、内核与时间"),
            ("uptime / env / history", "查看运行时长、变量与历史"),
            ("clear / help", "清空终端、显示帮助")
        ]
        var result = [TerminalLine("可用命令：", .info)]
        for row in rows {
            let padding = String(repeating: " ", count: max(1, 28 - row.0.count))
            result.append(TerminalLine("  \(row.0)\(padding)\(row.1)"))
        }
        return result
    }

    private func listLines(_ args: [String]) -> [TerminalLine] {
        let flags = args.filter { $0.hasPrefix("-") }
        let target = args.last { !$0.hasPrefix("-") } ?? "."
        let showHidden = flags.contains { $0.contains("a") }
        let longFormat = flags.contains { $0.contains("l") }

        let parts = components(for: target)
        guard let targetNode = node(at: parts) else {
            return [TerminalLine("ls: \(target): 没有那个文件或目录", .error)]
        }
        guard targetNode.isDirectory else {
            return [TerminalLine(longFormat ? longEntry(targetNode) : targetNode.name)]
        }

        var names = targetNode.children.keys.sorted()
        if !showHidden {
            names = names.filter { !$0.hasPrefix(".") }
        }
        guard !names.isEmpty else {
            return [TerminalLine("总计 0", .info)]
        }
        return names.compactMap { name in
            guard let child = targetNode.children[name] else { return nil }
            return TerminalLine(longFormat ? longEntry(child) : name + (child.isDirectory ? "/" : ""), child.isDirectory ? .info : .output)
        }
    }

    private func longEntry(_ node: Node) -> String {
        let permissions = node.isDirectory ? "drwxr-xr-x" : "-rw-r--r--"
        let size = node.isDirectory ? "4096" : "\(node.content.count)"
        let padding = String(repeating: " ", count: max(1, 6 - size.count))
        let stamp = stampFormatter.string(from: node.modifiedAt)
        return "\(permissions) \(userName) \(size)\(padding)\(stamp) \(node.name)"
    }

    private func changeDirectory(_ args: [String]) -> ([TerminalLine], Bool) {
        let target = args.first ?? "~"
        let parts = components(for: target)
        guard let node = node(at: parts) else {
            return ([TerminalLine("cd: \(target): 没有那个文件或目录", .error)], false)
        }
        guard node.isDirectory else {
            return ([TerminalLine("cd: \(target): 不是目录", .error)], false)
        }
        cwd = parts
        return ([], false)
    }

    private func concatenate(_ args: [String]) -> ([TerminalLine], Bool) {
        guard !args.isEmpty else {
            return ([TerminalLine("用法：cat <file>", .info)], false)
        }
        var output: [TerminalLine] = []
        for path in args {
            let parts = components(for: path)
            guard let fileNode = node(at: parts) else {
                output.append(TerminalLine("cat: \(path): 没有那个文件或目录", .error))
                continue
            }
            if fileNode.isDirectory {
                output.append(TerminalLine("cat: \(path): 是一个目录", .error))
                continue
            }
            if fileNode.content.isEmpty { continue }
            for line in fileNode.content.split(separator: "\n", omittingEmptySubsequences: false) {
                output.append(TerminalLine(String(line)))
            }
        }
        return (output, false)
    }

    private func makeDirectory(_ args: [String]) -> ([TerminalLine], Bool) {
        let recursive = args.contains("-p")
        let targets = args.filter { !$0.hasPrefix("-") }
        guard !targets.isEmpty else {
            return ([TerminalLine("用法：mkdir [-p] <dir>", .info)], false)
        }
        var output: [TerminalLine] = []
        for target in targets {
            let parts = components(for: target)
            guard let name = parts.last else {
                output.append(TerminalLine("mkdir: 路径无效", .error))
                continue
            }
            if recursive {
                if createDirectory(parts) == nil {
                    output.append(TerminalLine("mkdir: \(target): 无法创建目录", .error))
                }
            } else {
                guard let parent = node(at: Array(parts.dropLast())) else {
                    output.append(TerminalLine("mkdir: \(target): 没有那个文件或目录", .error))
                    continue
                }
                guard parent.isDirectory else {
                    output.append(TerminalLine("mkdir: \(target): 不是目录", .error))
                    continue
                }
                if parent.children[name] != nil {
                    output.append(TerminalLine("mkdir: \(target): 已存在", .error))
                } else {
                    parent.children[name] = Node(name: name, isDirectory: true)
                }
            }
        }
        return (output, false)
    }

    private func touchFile(_ args: [String]) -> ([TerminalLine], Bool) {
        guard !args.isEmpty else {
            return ([TerminalLine("用法：touch <file>", .info)], false)
        }
        var output: [TerminalLine] = []
        for target in args {
            let parts = components(for: target)
            guard let name = parts.last, !parts.isEmpty else {
                output.append(TerminalLine("touch: 路径无效", .error))
                continue
            }
            guard let parent = node(at: Array(parts.dropLast())) else {
                output.append(TerminalLine("touch: \(target): 没有那个文件或目录", .error))
                continue
            }
            if let existing = parent.children[name] {
                guard !existing.isDirectory else {
                    output.append(TerminalLine("touch: \(target): 是一个目录", .error))
                    continue
                }
                existing.modifiedAt = Date()
            } else {
                parent.children[name] = Node(name: name, isDirectory: false)
            }
        }
        return (output, false)
    }

    private func removePath(_ args: [String]) -> ([TerminalLine], Bool) {
        let recursive = args.contains { $0.hasPrefix("-") && $0.contains("r") }
        let targets = args.filter { !$0.hasPrefix("-") }
        guard !targets.isEmpty else {
            return ([TerminalLine("用法：rm [-r] <path>", .info)], false)
        }
        var output: [TerminalLine] = []
        for target in targets {
            let parts = components(for: target)
            guard !parts.isEmpty else {
                output.append(TerminalLine("rm: 无法删除根目录", .error))
                continue
            }
            guard let targetNode = node(at: parts) else {
                output.append(TerminalLine("rm: \(target): 没有那个文件或目录", .error))
                continue
            }
            if targetNode.isDirectory && !recursive {
                output.append(TerminalLine("rm: \(target): 是一个目录，请使用 -r", .error))
                continue
            }
            guard let parent = node(at: Array(parts.dropLast())) else {
                output.append(TerminalLine("rm: \(target): 无法删除", .error))
                continue
            }
            parent.children.removeValue(forKey: targetNode.name)
        }
        return (output, false)
    }

    private func tree(_ args: [String]) -> ([TerminalLine], Bool) {
        let target = args.last { !$0.hasPrefix("-") }
        let parts = target.map { components(for: $0) } ?? cwd
        guard let rootNode = node(at: parts) else {
            return ([TerminalLine("tree: \(target ?? "."): 没有那个文件或目录", .error)], false)
        }
        guard rootNode.isDirectory else {
            return ([TerminalLine(rootNode.name)], false)
        }
        var output = [TerminalLine("/" + parts.joined(separator: "/"), .info)]
        appendTree(rootNode, prefix: "", output: &output)
        return (output, false)
    }

    private func appendTree(_ node: Node, prefix: String, output: inout [TerminalLine]) {
        let names = node.children.keys.sorted()
        for (index, name) in names.enumerated() {
            guard let child = node.children[name] else { continue }
            let last = index == names.count - 1
            let branch = last ? "└── " : "├── "
            output.append(TerminalLine(prefix + branch + name + (child.isDirectory ? "/" : "")))
            if child.isDirectory {
                appendTree(child, prefix: prefix + (last ? "    " : "│   "), output: &output)
            }
        }
    }

    private func grepLines(_ args: [String]) -> ([TerminalLine], Bool) {
        var ignoreCase = false
        var operands: [String] = []
        for arg in args {
            if arg == "-i" {
                ignoreCase = true
            } else if !arg.hasPrefix("-") {
                operands.append(arg)
            }
        }
        guard operands.count >= 2 else {
            return ([TerminalLine("用法：grep [-i] <pattern> <file>", .info)], false)
        }
        let pattern = operands[0]
        var output: [TerminalLine] = []
        for path in operands.dropFirst() {
            let parts = components(for: path)
            guard let fileNode = node(at: parts), !fileNode.isDirectory else {
                output.append(TerminalLine("grep: \(path): 没有那个文件或目录", .error))
                continue
            }
            for (index, line) in fileNode.content.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let text = String(line)
                let matched = ignoreCase
                    ? text.lowercased().contains(pattern.lowercased())
                    : text.contains(pattern)
                if matched {
                    output.append(TerminalLine("\(index + 1):\(text)"))
                }
            }
        }
        if output.isEmpty {
            output.append(TerminalLine("没有匹配项。", .info))
        }
        return (output, false)
    }

    private func wordCount(_ args: [String]) -> ([TerminalLine], Bool) {
        let targets = args.filter { !$0.hasPrefix("-") }
        guard !targets.isEmpty else {
            return ([TerminalLine("用法：wc <file>", .info)], false)
        }
        var output: [TerminalLine] = []
        for path in targets {
            let parts = components(for: path)
            guard let fileNode = node(at: parts), !fileNode.isDirectory else {
                output.append(TerminalLine("wc: \(path): 没有那个文件或目录", .error))
                continue
            }
            let lineCount = fileNode.content.split(separator: "\n", omittingEmptySubsequences: false).count
            let wordCount = fileNode.content.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
            output.append(TerminalLine("\(lineCount) \(wordCount) \(fileNode.content.count) \(path)"))
        }
        return (output, false)
    }

    private func uptimeText() -> String {
        let seconds = Int(Date().timeIntervalSince(startedAt))
        let minutes = seconds / 60
        let remainder = seconds % 60
        let clock = String(format: "%02d:%02d", minutes, remainder)
        return "已运行 \(clock)，1 个用户，负载 0.00 0.01 0.00"
    }

    private func envLines() -> [TerminalLine] {
        [
            TerminalLine("USER=\(userName)"),
            TerminalLine("HOME=/\(home.joined(separator: "/"))"),
            TerminalLine("PWD=/\(cwd.joined(separator: "/"))"),
            TerminalLine("SHELL=/usr/bin/muse-sh"),
            TerminalLine("TERM=muse-256color"),
            TerminalLine("LANG=zh_CN.UTF-8"),
            TerminalLine("HOSTNAME=\(hostName)"),
            TerminalLine("SANDBOX=virtual")
        ]
    }

    private func historyLines() -> [TerminalLine] {
        guard !history.isEmpty else {
            return [TerminalLine("历史记录为空。", .info)]
        }
        return history.enumerated().map { index, command in
            TerminalLine(String(format: "%4d  %@", index + 1, command))
        }
    }

    private func writeToFile(_ path: String, text: String, append: Bool) -> TerminalLine? {
        let parts = components(for: path)
        guard let name = parts.last, !parts.isEmpty else {
            return TerminalLine("无法写入：路径无效", .error)
        }
        guard let parent = createDirectory(Array(parts.dropLast())) else {
            return TerminalLine("无法写入：\(path)", .error)
        }
        if let existing = parent.children[name], existing.isDirectory {
            return TerminalLine("无法写入：\(path): 是一个目录", .error)
        }
        var combined = append ? (parent.children[name]?.content ?? "") : ""
        if append && !combined.isEmpty && !text.isEmpty {
            combined += "\n"
        }
        combined += text
        if let existing = parent.children[name] {
            existing.content = combined
            existing.modifiedAt = Date()
        } else {
            parent.children[name] = Node(name: name, isDirectory: false, content: combined)
        }
        return nil
    }

    private func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?
        var index = input.startIndex
        while index < input.endIndex {
            let character = input[index]
            if let active = quote {
                if character == active {
                    quote = nil
                } else {
                    current.append(character)
                }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character == ">" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                let next = input.index(after: index)
                if next < input.endIndex && input[next] == ">" {
                    tokens.append(">>")
                    index = next
                } else {
                    tokens.append(">")
                }
            } else if character == " " || character == "\t" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(character)
            }
            index = input.index(after: index)
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    private func expand(_ path: String) -> String {
        if path == "~" { return "/" + home.joined(separator: "/") }
        if path.hasPrefix("~/") {
            return "/" + home.joined(separator: "/") + String(path.dropFirst(1))
        }
        return path
    }

    private func components(for path: String) -> [String] {
        let expanded = expand(path)
        var parts: [String] = expanded.hasPrefix("/") ? [] : cwd
        for piece in expanded.split(separator: "/", omittingEmptySubsequences: true) {
            let value = String(piece)
            if value == "." { continue }
            if value == ".." {
                if !parts.isEmpty { parts.removeLast() }
            } else {
                parts.append(value)
            }
        }
        return parts
    }

    private func node(at parts: [String]) -> Node? {
        var current = root
        for part in parts {
            guard current.isDirectory, let next = current.children[part] else { return nil }
            current = next
        }
        return current
    }

    @discardableResult
    private func createDirectory(_ parts: [String]) -> Node? {
        var current = root
        for part in parts {
            if let existing = current.children[part] {
                guard existing.isDirectory else { return nil }
                current = existing
            } else {
                let created = Node(name: part, isDirectory: true)
                current.children[part] = created
                current = created
            }
        }
        return current
    }

    @discardableResult
    private func writeFile(_ parts: [String], content: String) -> Bool {
        guard let name = parts.last else { return false }
        guard let parent = createDirectory(Array(parts.dropLast())) else { return false }
        if let existing = parent.children[name] {
            guard !existing.isDirectory else { return false }
            existing.content = content
            existing.modifiedAt = Date()
        } else {
            parent.children[name] = Node(name: name, isDirectory: false, content: content)
        }
        return true
    }
}
