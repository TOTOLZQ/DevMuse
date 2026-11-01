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
                title: "Ship the first IPA",
                body: "Build unsigned, sign locally, install, capture the first crash-free launch.",
                kind: .task,
                x: 250,
                y: 230
            ),
            NoteCard(
                title: "Offline-first state",
                body: "Every surface reads from one store. Network is an enhancement, never a dependency.",
                kind: .idea,
                x: 520,
                y: 340
            ),
            NoteCard(
                title: "Naming is design",
                body: "Board, Vault, Prompts. Three nouns that explain the whole app.",
                kind: .reference,
                x: 300,
                y: 520
            ),
            NoteCard(
                title: "Why is signing this hard?",
                body: "Certificates, provisioning profiles, entitlements. One missing link breaks the install.",
                kind: .question,
                x: 600,
                y: 590
            ),
            NoteCard(
                title: "Read: Swift concurrency",
                body: "Actors, structured tasks, and cancellation. Keep the store isolated on the main actor.",
                kind: .reference,
                x: 250,
                y: 760
            )
        ]
    }

    static var snippets: [Snippet] {
        [
            Snippet(
                title: "Debounce a value",
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
                tags: ["concurrency", "ui"]
            ),
            Snippet(
                title: "Decode JSON safely",
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
                tags: ["data", "json"]
            ),
            Snippet(
                title: "Fetch with async await",
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
                tags: ["network"]
            ),
            Snippet(
                title: "Undo the last commit",
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
                title: "Explain this diff",
                category: "Review",
                body: """
                Read the diff below and explain what changed in plain language.
                Call out risky behavior changes, missing tests, and anything that
                could break existing users. Keep it under 200 words.

                Diff:
                """
            ),
            PromptIdea(
                title: "Refactor for testability",
                category: "Refactor",
                body: """
                Refactor the following code so the core logic is pure and testable.
                Extract side effects to the edges. Do not change observable behavior.
                Return the refactored code plus a list of the tests you would write.

                Code:
                """
            ),
            PromptIdea(
                title: "Write a commit message",
                category: "Writing",
                body: """
                Write a conventional commit message for the staged changes.
                Subject under 72 characters, imperative mood, no trailing period.
                Body explains why, not what.

                Changes:
                """
            ),
            PromptIdea(
                title: "Pre-release checklist",
                category: "Ship",
                body: """
                Act as a release manager. Given this build, produce a checklist that
                covers versioning, signing, permissions, crash reporting, offline
                behavior, and rollback. Flag anything that blocks a store submission.
                """
            )
        ]
    }

    static var messages: [AgentMessage] {
        [
            AgentMessage(
                role: .assistant,
                content: """
                Hi, I am your development copilot. Ask me to review a diff, refactor a snippet, explain a concept, plan tests, or draft a release checklist. I run entirely on device.
                """
            )
        ]
    }
}
