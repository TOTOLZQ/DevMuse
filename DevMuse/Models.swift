import Foundation

enum CardKind: String, Codable, CaseIterable, Identifiable {
    case idea
    case question
    case reference
    case task

    var id: String { rawValue }
}

struct NoteCard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var kind: CardKind
    var x: Double
    var y: Double
    var createdAt: Date = Date()
}

struct Snippet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var language: String
    var code: String
    var tags: [String]
    var createdAt: Date = Date()
}

struct PromptIdea: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var category: String
    var body: String
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case paper
    case ink
    case system

    var id: String { rawValue }
}

enum AgentRole: String, Codable {
    case user
    case assistant
}

struct AgentMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var role: AgentRole
    var content: String
    var createdAt: Date = Date()
}

enum SeedData {
    static var cards: [NoteCard] {
        [
            NoteCard(
                title: "发布第一个 IPA",
                body: "构建未签名包，本地重签，安装，捕获第一次无崩溃启动。",
                kind: .task,
                x: 250,
                y: 230
            ),
            NoteCard(
                title: "离线优先的状态",
                body: "每个界面都从同一个 store 读取。网络只是增强，从不是依赖。",
                kind: .idea,
                x: 520,
                y: 340
            ),
            NoteCard(
                title: "命名即设计",
                body: "画布、代码库、提示词。三个名词解释整个应用。",
                kind: .reference,
                x: 300,
                y: 520
            ),
            NoteCard(
                title: "签名为什么这么难？",
                body: "证书、描述文件、权限。缺一个环节安装就失败。",
                kind: .question,
                x: 600,
                y: 590
            ),
            NoteCard(
                title: "阅读：Swift 并发",
                body: "Actor、结构化任务与取消。保持 store 在 main actor 上隔离。",
                kind: .reference,
                x: 250,
                y: 760
            )
        ]
    }

    static var snippets: [Snippet] {
        [
            Snippet(
                title: "防抖一个值",
                language: "Swift",
                code: """
                final class Debouncer {
                    private var task: Task<Void, Never>?

                    func run(delay: Duration, action: @escaping () -> Void) {
                        task?.cancel()
                        task = Task {
                            try? await Task.sleep(for: delay)
                            guard !Task.isCancelled else { return }
                            action()
                        }
                    }
                }
                """,
                tags: ["并发", "界面"]
            ),
            Snippet(
                title: "安全解码 JSON",
                language: "Swift",
                code: """
                struct Payload: Decodable {
                    let id: String
                    let title: String
                }

                func decode(_ data: Data) throws -> Payload {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    return try decoder.decode(Payload.self, from: data)
                }
                """,
                tags: ["数据", "json"]
            ),
            Snippet(
                title: "用 async await 请求",
                language: "Swift",
                code: """
                func fetch(_ url: URL) async throws -> Data {
                    var request = URLRequest(url: url)
                    request.timeoutInterval = 15
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let http = response as? HTTPURLResponse,
                          (200..<300).contains(http.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    return data
                }
                """,
                tags: ["网络"]
            ),
            Snippet(
                title: "撤销上一次提交",
                language: "Shell",
                code: """
                git reset --soft HEAD~1
                git status
                """,
                tags: ["git"]
            )
        ]
    }

    static var prompts: [PromptIdea] {
        [
            PromptIdea(
                title: "解释这个 diff",
                category: "审查",
                body: """
                阅读下面的 diff，用通俗的语言解释改了什么。
                指出有风险的行为变更、缺失的测试，以及任何可能
                影响现有用户的地方。控制在 200 字以内。

                Diff：
                """
            ),
            PromptIdea(
                title: "为可测试性重构",
                category: "重构",
                body: """
                重构下面的代码，让核心逻辑纯净且可测试。
                把副作用抽到边界。不要改变可观察行为。
                返回重构后的代码，以及你会写的测试清单。

                代码：
                """
            ),
            PromptIdea(
                title: "写一条提交信息",
                category: "写作",
                body: """
                为已暂存的改动写一条 conventional commit 信息。
                标题不超过 72 个字符，祈使语气，句末不加句号。
                正文解释为什么，而不是改了什么。

                改动：
                """
            ),
            PromptIdea(
                title: "发布前检查清单",
                category: "发布",
                body: """
                扮演发布经理。针对这个构建，给出一份覆盖版本号、
                签名、权限、崩溃上报、离线行为与回滚的清单。
                标出任何会阻塞上架的问题。
                """
            )
        ]
    }

    static var messages: [AgentMessage] {
        [
            AgentMessage(
                role: .assistant,
                content: """
                你好，我是你的开发副驾。可以让我审查 diff、重构片段、解释概念、规划测试，或起草发布清单。我完全在设备本地运行。
                """
            )
        ]
    }
}
