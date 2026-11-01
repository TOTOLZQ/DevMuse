import Foundation
import Combine

struct StoreSnapshot: Codable {
    var cards: [NoteCard]
    var snippets: [Snippet]
    var prompts: [PromptIdea]
    var messages: [AgentMessage]
    var appearance: AppAppearance
}

final class MuseStore: ObservableObject {
    @Published var cards: [NoteCard] = []
    @Published var snippets: [Snippet] = []
    @Published var prompts: [PromptIdea] = []
    @Published var messages: [AgentMessage] = []
    @Published var appearance: AppAppearance = .paper

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = directory.appendingPathComponent("muse-store.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(StoreSnapshot.self, from: data) else {
            cards = SeedData.cards
            snippets = SeedData.snippets
            prompts = SeedData.prompts
            messages = SeedData.messages
            appearance = .paper
            return
        }
        cards = snapshot.cards
        snippets = snapshot.snippets
        prompts = snapshot.prompts
        messages = snapshot.messages.isEmpty ? SeedData.messages : snapshot.messages
        appearance = snapshot.appearance
    }

    func save() {
        let snapshot = StoreSnapshot(
            cards: cards,
            snippets: snippets,
            prompts: prompts,
            messages: messages,
            appearance: appearance
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func setAppearance(_ value: AppAppearance) {
        appearance = value
        save()
    }

    func addCard(_ card: NoteCard) {
        cards.append(card)
        save()
    }

    func updateCard(_ card: NoteCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index] = card
        save()
    }

    func deleteCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        save()
    }

    func moveCard(_ id: UUID, dx: Double, dy: Double) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].x += dx
        cards[index].y += dy
        save()
    }

    func addSnippet(_ snippet: Snippet) {
        snippets.insert(snippet, at: 0)
        save()
    }

    func updateSnippet(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[index] = snippet
        save()
    }

    func deleteSnippet(_ id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    func addPrompt(_ prompt: PromptIdea) {
        prompts.insert(prompt, at: 0)
        save()
    }

    func updatePrompt(_ prompt: PromptIdea) {
        guard let index = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        prompts[index] = prompt
        save()
    }

    func deletePrompt(_ id: UUID) {
        prompts.removeAll { $0.id == id }
        save()
    }

    func resetAll() {
        cards = SeedData.cards
        snippets = SeedData.snippets
        prompts = SeedData.prompts
        messages = SeedData.messages
        appearance = .paper
        save()
    }

    func addUserMessage(_ content: String) {
        messages.append(AgentMessage(role: .user, content: content))
        save()
    }

    func appendAssistantMessage(_ content: String) {
        messages.append(AgentMessage(role: .assistant, content: content))
        save()
    }

    func clearConversation() {
        messages = SeedData.messages
        save()
    }

    func response(for input: String) -> String {
        let text = input.lowercased()
        if text.contains("review") || text.contains("diff") {
            return """
            Code review

            I read the change as three independent concerns:

            1. Behavior - the branch you added is reachable, but the early return skips the validation that the previous callers relied on. Add a unit test for the new path before merging.
            2. Side effects - the new code reads from a shared mutable state without isolation. Wrap it in an actor or pass the value explicitly.
            3. Surface - the error path returns a generic message. Surface the underlying reason so the caller can recover.

            Verdict: ship after the unit test lands. Everything else is a follow-up.
            """
        }
        if text.contains("refactor") {
            return """
            Refactor plan

            Move the side effect to the boundary:
            - Extract the pure core into a free function with no IO.
            - Return a result value instead of mutating an inout parameter.
            - Let the caller decide when to write to disk.

            After that, the core becomes trivial to test: feed inputs, assert outputs, no mocks.
            """
        }
        if text.contains("test") {
            return """
            Test plan

            Three layers:
            - Unit - cover the pure functions with boundary cases (empty, single, large, invalid).
            - Integration - exercise the store through its public API and assert persistence round-trips.
            - UI - snapshot the empty state and one populated state for each screen.

            One rule: every new branch ships with a failing test first.
            """
        }
        if text.contains("commit") {
            return """
            Commit message

            fix(core): stop mutating shared state on the main actor

            The previous implementation wrote to a shared dictionary inside a
            view update cycle, which produced inconsistent reads. Move the write
            behind the store's isolated queue and return the value to callers.
            """
        }
        if text.contains("ship") || text.contains("release") {
            return """
            Release checklist

            - Version bump matches the tagged commit
            - Signing identity and provisioning profile verified
            - No new NS* usage keys missing from Info.plist
            - Crash reporting integrated and symbolicated
            - Offline path runs without errors
            - Rollback tag exists and points to the last known-good build

            Gate: every item must be checked before upload.
            """
        }
        if text.contains("explain") || text.contains("what is") || text.contains("how") {
            return """
            Here is the shape of it.

            The system is a single source of truth wrapped in an observable store. Views read from it, user actions write to it, and every write persists to disk. Animations are handled by the view layer; the store never knows about them. That separation keeps the logic testable and the UI replaceable.

            If you tell me which part you want, I can go deeper.
            """
        }
        return """
        I can help with review, refactor, testing, commit messages, release checklists, and explanations. Paste a snippet or describe what you are working on and I will take it from there.
        """
    }
}
